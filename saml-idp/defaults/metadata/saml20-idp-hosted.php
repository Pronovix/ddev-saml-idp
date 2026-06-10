<?php
// #ddev-generated
/**
 * SAML 2.0 IdP configuration for SimpleSAMLphp.
 *
 * This file defines the metadata for the hosted Identity Provider.
 * It uses the runtime VIRTUAL_HOST to dynamically determine the Entity ID and endpoints.
 */

$idp_host = getenv('SAML_IDP_PRIMARY_HOST');

$metadata['https://' . $idp_host . '/simplesaml/saml2/idp/metadata'] = [
    'host' => '__DEFAULT__',
    'privatekey' => 'idp.key',
    'certificate' => 'idp.crt',
    'auth' => 'example-userpass',
    'sign.logout' => true,
];
