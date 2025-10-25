<?php

function custom_lando_smtp( $phpmailer ) {
	$phpmailer->isSMTP();
	$phpmailer->Host = 'mailhog';
	$phpmailer->SMTPAuth = false;
	$phpmailer->Port = 1025;
}

add_action( 'phpmailer_init', 'custom_lando_smtp' );
