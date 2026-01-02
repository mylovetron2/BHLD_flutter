<?php
/**
 * CORS Configuration for Flutter Web App
 * Add this file to handle Cross-Origin Resource Sharing
 */

// Allowed origins
$allowed_origins = [
    'https://mylovetron2.github.io',
    'https://bhldv2.web.app',
    'http://localhost',
    'http://localhost:3000',
    'http://localhost:8080',
];

// Get request origin
$origin = isset($_SERVER['HTTP_ORIGIN']) ? $_SERVER['HTTP_ORIGIN'] : '';

// Check if origin is allowed
if (in_array($origin, $allowed_origins)) {
    header("Access-Control-Allow-Origin: $origin");
} else {
    // For development: allow all origins (comment this out in production)
    header('Access-Control-Allow-Origin: *');
}

// Allow methods
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');

// Allow headers
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept');

// Allow credentials
header('Access-Control-Allow-Credentials: true');

// Cache preflight requests for 24 hours
header('Access-Control-Max-Age: 86400');

// Content type
header('Content-Type: application/json; charset=UTF-8');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}
?>
