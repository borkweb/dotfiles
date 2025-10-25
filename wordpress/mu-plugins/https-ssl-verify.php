<?php

add_filter( 'https_ssl_verify', '__return_false' );
add_filter( 'http_request_reject_unsafe_urls', '__return_false' );
add_filter( 'http_request_host_is_external', '__return_true' );