<?php
// #ddev-generated
/**
 * SAML 2.0 SP metadata for SimpleSAMLphp.
 *
 * This file defines the metadata for allowed Service Providers.
 * By default, it registers the local DDEV site as a Service Provider.
 */

$sp_host = getenv('SAML_SP_PRIMARY_HOST');

$sp_cert_file = '/var/www/simplesamlphp/certs/sp.crt';
if (!file_exists($sp_cert_file)) {
  throw new \RuntimeException(sprintf('SP certificate file not found at %s, have you forgotten to copy it?', $sp_cert_file));
}

$entityId = 'https://' . $sp_host;
$metadata[$entityId] = [
  'AssertionConsumerService' => [
    [
      'Binding' => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
      'Location' => $entityId . '/saml/acs',
    ],
  ],
  'SingleLogoutService' => [
    [
      'Binding' => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect',
      'Location' => $entityId . '/saml/sls',
    ],
  ],
  'certificate' => 'sp.crt',
];
