<?php
/**
 * Plugin Name: Show Plugin Directory Name
 * Description: Displays the plugin directory name in the plugins list
 * Version: 1.0
 */

add_filter('all_plugins', 'show_plugin_directory_name');

function show_plugin_directory_name($plugins) {
    if ( ! is_admin() ) {
        return $plugins;
    }

    foreach ($plugins as $plugin_file => $plugin_data) {
        $plugin_dir = dirname($plugin_file);

        if ($plugin_dir === '.') {
            continue;
        }

        $plugins[$plugin_file]['Description'] = sprintf(
            '<code>/%s</code> %s',
            $plugin_dir,
            $plugin_data['Description']
        );
    }

    return $plugins;
}
