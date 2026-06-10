<?php
// #ddev-generated
/**
 * SimpleSAMLphp Auth Sources configuration.
 *
 * Defines the authentication sources available for this IdP.
 * The primary auth source is 'example-userpass', which is configured with
 * pre-seeded test personas/users.
 */

$config = [
    'admin' => [
        'core:AdminPassword',
    ],
    'example-userpass' => [
        'exampleauth:UserPass',
        // Pre-seeded administrator persona
        'admin:password' => [
            'uid' => ['admin'],
            'eduPersonAffiliation' => ['member', 'employee', 'administrator'],
            'email' => ['admin@example.com'],
            'cn' => ['Admin User'],
            'sn' => ['User'],
            'givenName' => ['Admin'],
            'groups' => ['administrator', 'editor'],
        ],
        // Pre-seeded content editor persona
        'editor:password' => [
            'uid' => ['editor'],
            'eduPersonAffiliation' => ['member', 'employee', 'editor'],
            'email' => ['editor@example.com'],
            'cn' => ['Content Editor'],
            'sn' => ['Editor'],
            'givenName' => ['Content'],
            'groups' => ['editor'],
        ],
        // Pre-seeded standard test user
        'user1:password' => [
            'uid' => ['user1'],
            'eduPersonAffiliation' => ['member', 'employee'],
            'email' => ['user1@example.com'],
            'cn' => ['Test User 1'],
            'sn' => ['User'],
            'givenName' => ['Test'],
            'groups' => ['member'],
        ],
    ],
];
