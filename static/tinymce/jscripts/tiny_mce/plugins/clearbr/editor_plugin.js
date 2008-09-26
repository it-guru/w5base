
(function() {
	tinymce.create('tinymce.plugins.clearbr', {
		init : function(ed, url) {
			var t = this;

			t.editor = ed;

			ed.addCommand('mceClearBR', function() {
				ed.execCommand('mceInsertContent', false, '<br clear="all">');
			});

			ed.addButton('clearbr', {
                           image : url + '/img/clearbr.gif',
                           title : 'clearbr_desc', 
                           cmd : 'mceClearBR'});
		},





		getInfo : function() {
			return {
				longname : 'Insert clearbr',
				author : 'Vogler Hartmut',
				authorurl : 'http://tinymce.moxiecode.com',
				infourl : 'http://wiki.moxiecode.com/',
				version : tinymce.majorVersion + "." + tinymce.minorVersion
			};
		}

	});

	// Register plugin
	tinymce.PluginManager.add('clearbr', tinymce.plugins.clearbr);
})();
