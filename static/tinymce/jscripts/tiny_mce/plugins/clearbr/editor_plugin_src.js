tinyMCE.importPluginLanguagePack('clearbr', 'en,de'); // <- Add a comma separated list of all supported languages

// Singleton class
var TinyMCE_ClearBRPlugin = {
    getInfo : function() {
        return {
            longname : 'ClearBR plugin',
            author : 'Karin Uhlig',
            authorurl : 'http://www.modul.uhlig.at',
            infourl : 'http://www.modul.uhlig.at',
            version : "1.0"
        };
    },

    getControlHTML : function(cn) {
        switch (cn) {
            case "clearbr":
                return tinyMCE.getButtonHTML(cn, 'lang_clearbr_desc', '{$pluginurl}/images/clearbr.gif', 'mceClearBR', true);
        }

        return "";
    },

    execCommand : function(editor_id, element, command, user_interface, value) {
        // Handle commands
        switch (command) {
            // Remember to have the "mce" prefix for commands so they don't intersect with built in ones in the browser.
            case "mceClearBR":
                tinyMCE.execInstanceCommand(editor_id, 'mceInsertContent', false, '<br clear="all">');
                tinyMCE.triggerNodeChange(false);
                return true;
        }

        // Pass to next handler in chain
        return false;
    },

    onChange : function(inst) {
    }
};

// Adds the plugin class to the list of available TinyMCE plugins
tinyMCE.addPlugin("clearbr", TinyMCE_ClearBRPlugin);
