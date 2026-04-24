# Copyright 2016 The Johns Hopkins University Applied Physics Laboratory
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import datetime
from django.conf import settings
from django.urls import reverse
from django.contrib.auth import get_user_model
from django.core.exceptions import SuspiciousOperation
from rest_framework.exceptions import AuthenticationFailed
from rest_framework.settings import import_from_string
from rest_framework.authentication import get_authorization_header

from django.utils.encoding import force_bytes, smart_text, smart_bytes
from django.utils.translation import ugettext as _
from mozilla_django_oidc.auth import OIDCAuthenticationBackend
from mozilla_django_oidc.utils import absolutify, import_from_settings

from bossoidc2.models import Keycloak as KeycloakModel
from jwkest.jwt import JWT
from josepy.jws import JWS, Header

from keycloak.realm import KeycloakRealm
from kpi.utils.log import logging as kpi_logging

from oc.utils import get_subdomain

import requests
import logging

LOGGER = logging.getLogger(__name__)

def _log(child):
    return logging.getLogger(__name__).getChild(child)

def load_user_roles(user, roles):
    """Default implementation of the LOAD_USER_ROLES callback

    Args:
        user (UserModel): Django user object for the user logging in
        roles (list[str]): List of Keycloak roles assigned to the user
                           Note: Contains both realm roles and client roles
    """
    pass

LOAD_USER_ROLES = getattr(settings, 'LOAD_USER_ROLES', None)
if LOAD_USER_ROLES is None:
    # DP NOTE: had issues with import_from_string loading bossoidc.backend.load_user_roles
    LOAD_USER_ROLES_FUNCTION = load_user_roles
else: # pragma: no cover
    LOAD_USER_ROLES_FUNCTION = import_from_string(LOAD_USER_ROLES, 'LOAD_USER_ROLES')

KEYCLOAK_ADMIN_USER = getattr(settings, 'KEYCLOAK_ADMIN_USER', 'bossadmin')


def update_user_data(user, userinfo):
    """Default implementation of the UPDATE_USER_DATA callback

    Args:
        user (UserModel): Django user object for the user logging in
        userinfo (dict): Dictionary of userinfo requested from Keycloak with the
                         user's profile data
    """
    pass

UPDATE_USER_DATA = getattr(settings, 'UPDATE_USER_DATA', None)
if UPDATE_USER_DATA is None:
    UPDATE_USER_DATA_FUNCTION = update_user_data
else: # pragma: no cover
    UPDATE_USER_DATA_FUNCTION = import_from_string(UPDATE_USER_DATA, 'UPDATE_USER_DATA')


def check_username(username):
    """Ensure that the given username does exceed the current user models field
    length

    Args:
        username (str): Username of the user logging in

    Raises:
        AuthenticationFailed: If the username length exceeds the fields max length
    """
    username_field = get_user_model()._meta.get_field("username")
    if len(username) > username_field.max_length:
        raise AuthenticationFailed(_('Username is too long for Django'))


def get_user_by_id(request, userinfo):
    """Get or create the user object based on the user's information

    Note: Taken from djangooidc.backends.OpenIdConnectBackend and made common for
    drf-oidc-auth to make use of the same create user functionality

    Note: The user's token is loaded from the request session or header to load_user_roles
    the user's Keycloak roles

    Args:
        request (Request): Django request from the user
        userinfo (dict): Dictionary of userinfo requested from Keycloak with the
                         user's profile data

    Returns:
        UserModel: user object for the requesting user
        None: If the requesting user's token's audience is not valid

    Raises:
        AuthenticationFailed: If the requesting user's username is too long
    """

    access_token = get_access_token(request)
    audience = get_token_audience(access_token)
    # if not token_audience_is_valid(audience):
    #     return None

    subdomain = request.session["subdomain"]

    return get_user_with_id(access_token, userinfo, subdomain)

def get_user_with_id(access_token, userinfo, subdomain=None):
    """Common functionality for getting or creating the user.  Used by both
    mozilla_django_oidc and drf-oidc-auth.

    Args:
        access_token ():
        userinfo (dict): Dictionary of userinfo requested from Keycloak with the

    Returns:
        UserModel: user object for the requesting user
        None: If the requesting user's token's audience is not valid

    Raises:
        AuthenticationFailed: If the requesting user's username is too long
    """
    UserModel = get_user_model()
    uid = userinfo['sub']
    usersubdomain = subdomain
    username = userinfo['preferred_username'] + "+" + usersubdomain
    usertype = userinfo['https://www.openclinica.com/userContext']['userType']

    check_username(username)

    # Some OP may actually choose to withhold some information, so we must test if it is present
    openid_data = {'last_login': datetime.datetime.now()}
    if 'first_name' in userinfo.keys():
        openid_data['first_name'] = userinfo['first_name']
    if 'given_name' in userinfo.keys():
        openid_data['first_name'] = userinfo['given_name']
    if 'christian_name' in userinfo.keys():
        openid_data['first_name'] = userinfo['christian_name']
    if 'family_name' in userinfo.keys():
        openid_data['last_name'] = userinfo['family_name']
    if 'last_name' in userinfo.keys():
        openid_data['last_name'] = userinfo['last_name']
    if 'email' in userinfo.keys():
        openid_data['email'] = userinfo['email']

    # DP NOTE: The thing that we are trying to prevent is the user account being
    #          deleted and recreated in Keycloak (all user data the same, but a
    #          different uid) and getting the application permissions of the old
    #          user account.

    try: # try to lookup by keycloak UID first
        kc_user = KeycloakModel.objects.get(UID = uid, subdomain = usersubdomain)
        user = kc_user.user
        # Always sync user_type so user type changes in Keycloak are reflected on the next login
        if kc_user.user_type != usertype:
            kc_user.user_type = usertype
            kc_user.save()
    except KeycloakModel.DoesNotExist: # user doesn't exist with a keycloak UID and subdomain
        try:
            user = UserModel.objects.get_by_natural_key(username)

            fmt = "Deleting user '{}' because it matches the authenticated Keycloak username"
            _log('get_user_by_id').info(fmt.format(username))

            # remove existing user account, so permissions are not transfered
            # DP NOTE: required, as the username field is still a unique field,
            #          which doesn't allow multiple users in the table with the
            #          same username
            user.delete()
        except UserModel.DoesNotExist:
            pass

        args = {UserModel.USERNAME_FIELD: username, 'defaults': openid_data, }
        user, created = UserModel.objects.update_or_create(**args)
        kc_user = KeycloakModel.objects.create(user = user, UID = uid, subdomain = usersubdomain)
        if kc_user:
            kc_user.user_type = usertype
            kc_user.save()

    roles = get_roles(access_token)
    user.is_staff = 'admin' in roles or 'superuser' in roles
    user.is_superuser = 'superuser' in roles

    LOAD_USER_ROLES_FUNCTION(user, roles)
    UPDATE_USER_DATA_FUNCTION(user, userinfo)

    user.save()
    return user


def get_roles(decoded_token):
    """Get roles declared in the input token

    Note: returns both the realm roles and client roles

    Args:
        decoded_token (dict): The user's decoded bearer token

    Returns:
        list[str]: List of role names
    """

    # Extract realm scoped roles
    LOGGER.debug(
            "LOGGER from OCAuthenticationBackend"
        )
    _log('get_roles').info('get_roles 1')
    try:
        # Session logins and Bearer tokens from password Grant Types
        if 'realm_access' in decoded_token:
            roles = decoded_token['realm_access']['roles']
        else: #  Bearer tokens from authorization_code Grant Types
              # DP ???: a session login uses an authorization_code code, not sure
              #         about the difference
            roles = decoded_token['resource_access']['account']['roles']
    except KeyError:
        roles = []

    # Extract all client scoped roles
    for name, client in decoded_token.get('resource_access', {}).items():
        if name == 'account':
            continue

        try:
            roles.extend(client['roles'])
        except KeyError: # pragma no cover
            pass

    return roles


def get_access_token(request):
    """Retrieve access token from the request

    The access token is searched first the request's session. If it is not
    found it is then searched in the request's ``Authorization`` header.

    Args:
        request (Request): Django request from the user

    Returns:
        dict: JWT payload of the bearer token
    """
    access_token = request.session.get("access_token")
    if access_token is None:  # Bearer token login
        access_token = get_authorization_header(request).split()[1]
    return JWT().unpack(access_token).payload()


def get_token_audience(token):
    """Retrieve the token's intended audience

    According to the openid-connect spec `aud` may be a string or a list:
        http://openid.net/specs/openid-connect-basic-1_0.html#IDToken

    Args:
        token (dict): The user's decoded bearer token

    Returns:
        list[str]: The list of token audiences
    """

    aud = token.get("aud", [])
    return [aud] if isinstance(aud, str) else aud


def token_audience_is_valid(audience):
    """Check if the input audiences is valid

    Args:
        audience (list[str]): List of token audiences

    Returns:
        bool: If any of the audience is in the list of requested audiences
    """

    if not hasattr(settings, 'OIDC_AUTH'):
        # Don't assume that the bossoidc settings module was used
        return False

    trusted_audiences = settings.OIDC_AUTH.get('OIDC_AUDIENCES', [])

    for aud in audience:
        if aud in trusted_audiences:
            result = True
            break
    else:
        result = False
    return result


def get_realm_name(request):
    subdomain = get_subdomain(request)
    realm_name = subdomain

    allowed_connections_url = '{}/customer-service/api/allowed-connections'.format(settings.OC_BUILD_URL)
    allowed_connections_response = None
    try:
        allowed_connections_response = requests.get(
                allowed_connections_url,
                params = { 'subdomain': subdomain }
            )
    except Exception as e:
        kpi_logging.error("oc.backend __get_realm {}".format(str(e)), exc_info=True)

    if isinstance(allowed_connections_response, requests.Response):
        realm_name = allowed_connections_response.json()[0]

    return realm_name

def get_client_secret(realm_name):
    master_realm = KeycloakRealm(server_url=settings.KEYCLOAK_AUTH_URI, realm_name=settings.KEYCLOAK_MASTER_REALM)
    master_realm_client = master_realm.open_id_connect(
        client_id=settings.KEYCLOAK_ADMIN_CLIENT_ID,
        client_secret=settings.KEYCLOAK_ADMIN_CLIENT_SECRET
    )

    token = master_realm_client.client_credentials()
    access_token = token['access_token']

    admin_client = master_realm.admin
    admin_client.set_token(access_token)

    clients = admin_client.realms.by_name(realm_name).clients.all()
    clientId = settings.KEYCLOAK_CLIENT_ID
    client_id = None
    for client in clients:
        if client['clientId'] == clientId:
            client_id = client['id']
            break

    client_secret = None
    if client_id is not None:
        client_secret = admin_client.realms.by_name(realm_name).clients.by_id(client_id).client_secret()['value']

    return client_secret

class OpenIdConnectBackend(OIDCAuthenticationBackend): # pragma: no cover
    """Subclass of the Django OIDC Backend that makes use of our get_user_by_id
    implementation
    """

    def configure(self, request):
        realm_name = get_realm_name(request)
        if isinstance(realm_name, str):
            client_secret = get_client_secret(realm_name)
            if client_secret is not None:
                self.OIDC_OP_AUTHORIZATION_ENDPOINT = '{}/auth/realms/{}/protocol/openid-connect/auth'.format(settings.KEYCLOAK_AUTH_URI, realm_name)
                self.OIDC_OP_TOKEN_ENDPOINT = '{}/auth/realms/{}/protocol/openid-connect/token'.format(settings.KEYCLOAK_AUTH_URI, realm_name)
                self.OIDC_OP_USER_ENDPOINT = '{}/auth/realms/{}/protocol/openid-connect/userinfo'.format(settings.KEYCLOAK_AUTH_URI, realm_name)
                self.OIDC_OP_JWKS_ENDPOINT = '{}/auth/realms/{}/protocol/openid-connect/certs'.format(settings.KEYCLOAK_AUTH_URI, realm_name)
                self.OIDC_RP_CLIENT_SECRET = client_secret

    def __init__(self, *args, **kwargs):
        """Initialize settings."""
        self.OIDC_OP_TOKEN_ENDPOINT = self.get_settings("OIDC_OP_TOKEN_ENDPOINT", None)
        self.OIDC_OP_USER_ENDPOINT = self.get_settings("OIDC_OP_USER_ENDPOINT", None)
        self.OIDC_OP_JWKS_ENDPOINT = self.get_settings("OIDC_OP_JWKS_ENDPOINT", None)
        self.OIDC_RP_CLIENT_ID = self.get_settings("OIDC_RP_CLIENT_ID", None)
        self.OIDC_RP_CLIENT_SECRET = self.get_settings("OIDC_RP_CLIENT_SECRET", None)
        self.OIDC_RP_SIGN_ALGO = self.get_settings("OIDC_RP_SIGN_ALGO", "HS256", None)
        self.OIDC_RP_IDP_SIGN_KEY = self.get_settings("OIDC_RP_IDP_SIGN_KEY", None)

        self.UserModel = get_user_model()

    def authenticate(self, request, **kwargs):
        """Authenticates a user based on the OIDC code flow."""

        if self.OIDC_OP_TOKEN_ENDPOINT is None:
            self.configure(request)

        self.request = request
        if not self.request:
            return None

        state = self.request.GET.get("state")
        code = self.request.GET.get("code")
        nonce = kwargs.pop("nonce", None)

        if not code or not state:
            return None

        reverse_url = self.get_settings(
            "OIDC_AUTHENTICATION_CALLBACK_URL", "oidc_authentication_callback"
        )

        token_payload = {
            "client_id": self.OIDC_RP_CLIENT_ID,
            "client_secret": self.OIDC_RP_CLIENT_SECRET,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": absolutify(self.request, reverse(reverse_url)),
        }

        # Get the token
        token_info = self.get_token(token_payload)
        id_token = token_info.get("id_token")
        access_token = token_info.get("access_token")

        # Validate the token
        payload = self.verify_token(id_token, nonce=nonce)

        if payload:
            self.store_tokens(access_token, id_token)
            self.store_user_info(access_token)
            self.store_customer_info(access_token)
            try:
                return self.get_or_create_user(access_token, id_token, payload, get_subdomain(request))
            except SuspiciousOperation as exc:
                LOGGER.warning("failed to get or create user: %s", exc)
                return None

        return None

    def store_user_info(self, access_token):
        """Extract userUuid from the access token's userContext claim and store
        them in the session.
        Args:
            access_token (str): Raw (encoded) OIDC access token
        """
        try:
            decoded_token = JWT().unpack(access_token).payload()
            user_context = decoded_token.get(
                'https://www.openclinica.com/userContext', {}
            )
            user_uuid = user_context.get('userUuid')
        except Exception as e:
            LOGGER.error('Failed to extract userUuid from access_token: %s', e)
            return

        if not user_uuid:
            LOGGER.error('Empty userUuid is received from access_token')
            return

        self.request.session['oc_user_uuid'] = user_uuid

    def store_customer_info(self, access_token):
        """Fetch customer information from customer-service using the customerUuid
        from the access token and store it in the session.

        Args:
            access_token (str): Raw (encoded) OIDC access token
        """
        try:
            decoded_token = JWT().unpack(access_token).payload()
            user_context = decoded_token.get(
                'https://www.openclinica.com/userContext', {}
            )
            customer_uuid = user_context.get('customerUuid')
        except Exception as e:
            LOGGER.error('Failed to extract customerUuid from access_token: %s', e)
            return

        if not customer_uuid:
            LOGGER.error('Empty customerUuid is received from access_token')
            return

        customer_url = '{}/customer-service/api/customers/{}'.format(
            settings.OC_BUILD_URL, customer_uuid
        )
        headers = {'Authorization': 'Bearer {}'.format(access_token)}
        try:
            response = requests.get(customer_url, headers=headers, timeout=10)
            response.raise_for_status()
            customer_data = response.json()
            customer_name = customer_data.get('name')
            customer_shared_infra = customer_data.get('sharedInfra', False)
        except Exception as e:
            LOGGER.error(
                'Failed to retrieve customer info for customerUuid: %s, %s',
                customer_uuid, e
            )
            return

        self.request.session['oc_customer_name'] = customer_name
        self.request.session['oc_customer_shared_infra'] = customer_shared_infra

    def retrieve_matching_jwk(self, token):
        """Get the signing key by exploring the JWKS endpoint of the OP.

        Overriding original method because KeyCloak isn't providing the key id
        in the token.  Since there's only one jwks key, try using that key
        to verify the token's signature.

        Args:
            token

        Returns:
            Public signing key for the KeyCloak realm.

        Raises:
            (SuspiciousOperation)
        """
        _log('retrieve_matching_jwk').info('retrieve_matching_jwk 1')
        response_jwks = requests.get(
            self.OIDC_OP_JWKS_ENDPOINT,
            verify=self.get_settings('OIDC_VERIFY_SSL', True)
        )
        response_jwks.raise_for_status()
        jwks = response_jwks.json()

        # Compute the current header from the given token to find a match
        jws = JWS.from_compact(token)
        json_header = jws.signature.protected
        header = Header.json_loads(json_header)

        key = None
        num_keys = len(jwks['keys'])
        for jwk in jwks['keys']:
            # If there's only one key, then try it even if the key id doesn't
            # match or is None.
            if jwk['kid'] != smart_text(header.kid) and num_keys > 1:
                continue
            if 'alg' in jwk and jwk['alg'] != smart_text(header.alg):
                raise SuspiciousOperation('alg values do not match.')
            key = jwk
        if key is None:
            raise SuspiciousOperation('Could not find a valid JWKS.')
        return key

    def verify_claims(self, claims):
        """Ensure required claims provided.

        Claims are specified by the OIDC_RP_SCOPES variable in the Django
        settings.

        Args:
            claims (list[str]): Claims provided.

        Returns:
            (boolean)
        """
        _log('verify_claims').info('verify_claims 1')
        scopes = self.get_settings('OIDC_CLAIMS_VERIFICATION', 'preferred_username sub').split()

        for field in scopes:
            if field == 'email':
                # We don't provide an email address when we create bossadmin,
                # so don't require email if this is the bossadmin user.
                if 'preferred_username' in claims and claims['preferred_username'] == KEYCLOAK_ADMIN_USER:
                    continue
            if field not in claims:
                return False

        return True

    def get_or_create_user(self, access_token, id_token, payload, subdomain):
        """Get or create the user based on the provided arguments.

        Args:
            access_token
            id_token
            payload

        Returns:
            User info.

        Raises:
            (SuspiciousOperation): When not all required claims provided.
        """
        _log('get_or_create_user').info('get_or_create_user 1')
        user_info = self.get_userinfo(access_token, id_token, payload)
        claims_verified = self.verify_claims(user_info)
        if not claims_verified:
            msg = 'Claims verification failed'
            raise SuspiciousOperation(msg)

        decoded_token = JWT().unpack(access_token).payload()
        user = get_user_with_id(decoded_token, user_info, subdomain)
        return user
