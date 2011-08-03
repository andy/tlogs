jQuery(function() {
    jQuery('textarea.wymeditor').wymeditor({ 
        lang: 'ru',
        skin: 'default',
        jQueryPath: '/packages/js/application.js',
        wymPath: '/packages/js/publish.js',
        basePath: '/images/wymeditor/',
        skinPath: '/images/wymeditor/skins/default/',
        logoHtml: '',
        toolsItems: [
            {'name': 'Bold', 'title': 'Strong', 'css': 'wym_tools_strong'}, 
            {'name': 'Italic', 'title': 'Emphasis', 'css': 'wym_tools_emphasis'},
            // {'name': 'Superscript', 'title': 'Superscript',
            //     'css': 'wym_tools_superscript'},
            // {'name': 'Subscript', 'title': 'Subscript',
            //     'css': 'wym_tools_subscript'},
            {'name': 'InsertOrderedList', 'title': 'Ordered_List',
                'css': 'wym_tools_ordered_list'},
            {'name': 'InsertUnorderedList', 'title': 'Unordered_List',
                'css': 'wym_tools_unordered_list'},
            // {'name': 'Indent', 'title': 'Indent', 'css': 'wym_tools_indent'},
            // {'name': 'Outdent', 'title': 'Outdent', 'css': 'wym_tools_outdent'},
            {'name': 'CreateLink', 'title': 'Link', 'css': 'wym_tools_link'},
            {'name': 'Unlink', 'title': 'Unlink', 'css': 'wym_tools_unlink'},
            {'name': 'InsertImage', 'title': 'Image', 'css': 'wym_tools_image'},
            // {'name': 'InsertTable', 'title': 'Table', 'css': 'wym_tools_table'},
            // {'name': 'Paste', 'title': 'Paste_From_Word',
            //     'css': 'wym_tools_paste'},
            {'name': 'Undo', 'title': 'Undo', 'css': 'wym_tools_undo'},
            {'name': 'Redo', 'title': 'Redo', 'css': 'wym_tools_redo'},
            {'name': 'ToggleHtml', 'title': 'HTML', 'css': 'wym_tools_html'}
            // {'name': 'Preview', 'title': 'Preview', 'css': 'wym_tools_preview'}
        ],
        postInit: function(wym) {
        
            //postInit is executed after WYMeditor initialization
            //'wym' is the current WYMeditor instance
            
            //we generally activate plugins after WYMeditor initialization

            //activate 'hovertools' plugin
            //which gives advanced feedback to the user:
            wym.hovertools();
            wym.resizable({ handles: "s,e", maxHeight: 600 });
        }
        
    });
});