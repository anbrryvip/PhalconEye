{% extends "layouts/admin.volt" %}

{% block title %}{{ 'Pages' | trans }}{% endblock %}

{% block head %}
    <script type="text/javascript">
    //var currentLayoutType =  'top,right,middle,left,bottom';
    var currentLayoutType = '{{currentPage.getLayout()}}';
    var currentPageId = '{{currentPage.getId()}}';
    var notSaved = false;
    var bundlesWidgetsMetadata = [];
    var widgetsListData = [];
    var widgetsParams = [];
    var elementIdCounter = 1;

    window.onload = function () {
        bundlesWidgetsMetadata = $.parseJSON('{{bundlesWidgetsMetadata}}');
        widgetsListData = $.parseJSON('{{widgetsListData}}');


        if (currentPageId == -1) {
            $("#remove-button").remove();
        }

        window.onbeforeunload = function () {
            if (notSaved)
                return "{{ "Page not saved! Dou you want to leave?" | trans}}";
        };

        buildWidgetsList();

        $('.widget').draggable({
            helper:'clone',
            connectToSortable:".widgets_placer"
        });


        changeCurrentLayoutType(currentLayoutType);
        setWidgetsList({{currentPageWidgets}}, true);

        $(".widget_tooltip").tooltip({
            position:"center left"
        });

        $("#form_page").change(function () {
            $("#form_page").parent().submit();
        });
    };

    var defaultWidgetControl = function (widget) {
        return   '<div style="display: block;" class="delete_widget to_remove"><a href="javascript:;" onclick="editAction($(this));" content_id="'+widget.id+'" widget_current_id="'+widget.widget_id+'" widget_page_id="'+currentPageId+'">{{ "Edit" | trans}}</a>&nbsp;|&nbsp;<a href="javascript:;"  onclick="removeAction($(this));">X</a></div>';
    }

    var buildWidgetsList = function () {
        $.each(bundlesWidgetsMetadata, function (i, l) {
            $("#widget_list ul").append('<li class="widget_seperator">' + i + '</li>');
            $.each(l, function (i, l) {
                $("#widget_list ul").append('<li title="' + l.description + '" class="widget_tooltip widget" widgetid="0" widget_object_id="' + l.widget_id + '" widget="' + l.name + '">' + l.name + defaultWidgetControl(l) + '</li>');
            });
            $("#widget_list ul").find('.delete_widget').css('display', 'none');
        });
    }

    var setEditedWidgetParams = function (params) {
        widgetsParams[$("#widget_editing").attr('element_id')] = JSON.parse(JSON.stringify(params));

        $("#widget_editing").attr("id", "");
        changePageState(true);
    }

    var savePage = function () {
        if (!notSaved) return;

        $.getJSON("/admin/pages/save-layout/{{currentPage.getId()}}",
                {
                    format:"json",
                    layout:currentLayoutType,
                    items:getWidgetsList(true)
                }, function(){
                    changePageState(false);
                    alert('{{ 'Changes saved!' |trans }}');
                    window.location.reload();
                }).error(function() { changePageState(true); alert("{{ 'Error while saving...' |trans }}"); });
    }

    var editAction = function(element){
        if ($('#widget_editing'))
            $('#widget_editing').attr('id', '');

        element.parent().parent().attr('id', 'widget_editing');

        var url = '/admin/pages/widgetOptions';
        var data = {
            'id': element.attr('content_id'),
            'widget_id': element.attr('widget_current_id'),
            'page_id': element.attr('widget_page_id'),
            'params': widgetsParams[element.parent().parent().attr('element_id')]
        };

        PE.modal.open(url, data);
    }

    var removeAction = function(element){
        element.parent().parent().remove();
        changePageState(true);
    }

    var changePageState = function (state) {

        if (state){
            $('#save_button').attr("disabled", null);
            $('#save_button').html("{{"Save (NOT  SAVED)" | trans}}");
        }
        else{
            $('#save_button').attr("disabled", "disabled");
            $('#save_button').html("{{"Save" | trans}}");
        }
        $('#save_button').button('reset')
        notSaved = state;
    }

    var bindDraggable = function () {
        $(".widgets_placer").sortable({
            connectWith:'.widgets_placer',
            start:function (event, ui) {
                changePageState(true);
            },
            receive:function (event, ui) {
                $(".admin_pages_layout").find('.delete_widget').css('display', 'block');
                updateLayoutPanelsHeight();
            }
        });

        $("ul, li").disableSelection();
    }

    var getWidgetsList = function ($no_content) {
        var items = [];

        $(".widgets_placer").each(function () {
            $(this).find(".widget").each(function () {
                items.push({
                    "content":(!$no_content ? $(this).html().trim() : ''),
                    "id":$(this).attr("widgetid"),
                    "widget_id":$(this).attr("widget_object_id"),
                    "params":widgetsParams[$(this).attr('element_id')],
                    "layout":$(this).parent().attr("layout")
                });
            });
        });

        return items;
    }

    var setWidgetsList = function (list, is_initial) {
        if (!is_initial) {
            var hasRemove = false;

            $.each(list, function (i, l) {
                widgetsParams[elementIdCounter] = l.params;
                if ($("#widgets_container_" + l.layout).length > 0) {
                    $("#widgets_container_" + l.layout).append('<li element_id="'+elementIdCounter+'" class="widget" widgetid="' + l.id + '" widget_object_id="' + l.widget_id + '">' + l.content + '</div>');
                    elementIdCounter++;
                }
                else hasRemove = true;
            });

            return hasRemove;
        }
        else {
            list = JSON.parse(JSON.stringify(list));
            $.each(list, function (i, l) {
                widgetsParams[elementIdCounter] = l.params;
                if ($("#widgets_container_" + l.layout).length > 0) {
                    // get widget real title
                    if (widgetsListData[l.widget_id])
                        var title = widgetsListData[l.widget_id].name;
                    else
                        var title = "<b style='color: red;'>{{ "NOT FOUND" | trans}}</b>";
                    $("#widgets_container_" + l.layout).append('<li element_id="'+elementIdCounter+'" class="widget" widgetid="' + l.id + '" widget_object_id="' + l.widget_id + '">' + title + defaultWidgetControl(l) + '</div>');
                    elementIdCounter++;
                }
            });
        }
    }


    var updateLayoutPanelsHeight = function () {
        // get max height;
        var maxHeight = 0;

        if ($("#widgets_container_middle")) if (maxHeight < $("#widgets_container_middle").height()) maxHeight = $("#widgets_container_middle").height();
        if ($("#widgets_container_left")) if (maxHeight < $("#widgets_container_left").height()) maxHeight = $("#widgets_container_left").height();
        if ($("#widgets_container_right")) if (maxHeight < $("#widgets_container_right").height()) maxHeight = $("#widgets_container_right").height();

        // setting to all height{
        if ($("#widgets_container_middle")) $("#widgets_container_middle").css("min-height", maxHeight + "px");
        if ($("#widgets_container_left")) $("#widgets_container_left").css("min-height", maxHeight + "px");
        if ($("#widgets_container_right")) $("#widgets_container_right").css("min-height", maxHeight + "px");

    }

    var changeCurrentLayoutType = function (type, widgetsList) {
        // Header or Footer
        if (type == "special") {
            $("#change-layout-button").remove();
            $("#remove-button").remove();

            $("#global_placer").append('<ul layout="special" id="widgets_container_special" class="admin_pages_layout widgets layout_middle widgets_placer"></ul>');
            $("#widgets_container_special").css("width", "759px !important");
            bindDraggable();

            return;
        }

        // Normal pages
        var types = type.split(',');

        //getting existing widgets
        if (!widgetsList)
            widgetsList = getWidgetsList();

        // removing existing placers
        $("#global_placer").html('');

        // header
        $("#global_placer").append('<div class="admin_pages_layout layout_header"><span>{{ "Header" | trans}}</span></div>');

        // adding new placers
        $.each(types, function (i, l) {
            $("#global_placer").append('<ul layout="' + l + '" id="widgets_container_' + l + '" class="admin_pages_layout widgets layout_' + l + ' widgets_placer"></ul>');
        });

        // footer
        $("#global_placer").append('<div class="admin_pages_layout layout_footer"><span>{{ "Footer" | trans}}</span></div>');


        // correcting middle placer
        if ($("#widgets_container_middle")) {
            if (types.indexOf('left') != -1 && types.indexOf('right') != -1) {
                if (window.opera)
                    $("#widgets_container_middle").attr("style", "width: 365px !important");
                else
                    $("#widgets_container_middle").attr("style", "width: 366px !important");
            }
            else if (types.indexOf('left') != -1 || types.indexOf('right') != -1) {
                if (window.opera)
                    $("#widgets_container_middle").attr("style", "width: 549px !important");
                else
                    $("#widgets_container_middle").attr("style", "width: 550px !important");
            }
            else {
                $("#widgets_container_middle").attr("style", "width: 734px !important");
            }
        }

        // setting widgets list
        var hasRemove = setWidgetsList(widgetsList);

        if (hasRemove) {
            if (!confirm("{{ "If you switch to new layout you will lose some widgets, are you shure?" | trans}}")) {
                changeCurrentLayoutType(currentLayoutType, widgetsList);
                return;
            }
        }

        bindDraggable();
        if (currentLayoutType != type) {
            changePageState(true);
            currentLayoutType = type;
        }
    }


    </script>
{% endblock %}

{% block content %}

    <div class="row-fluid">
        <div class="manage_page_header">
            <div class="manage_page_header_label">
                <h3><a href="/admin/pages" class='btn'>{{ "<< Back" | trans }}</a> | {{ "Manage page" | trans }}</h3>
                <a href="{% if currentPage.getType() is null %}/page{{ currentPage.getUrl() }}{% else %}javascript:;{% endif %}" target="_blank">{{ currentPage.getTitle() }}</a>
            </div>

            <div class="widget_options_panel">

                <div class="btn-group">
                    <a class="btn btn-inverse dropdown-toggle" data-toggle="dropdown" href="#">
                        {{ "Change layout" | trans }}
                        <span class="caret"></span>
                    </a>
                    <ul class="dropdown-menu">
                        <li>
                            <div id="layout_select_block">
                                <div class="admin_layoutbox_menu_columnchoices_instructions">
                                    {{ "Select layout type for current page" | trans }}
                                </div>
                                <ul class="admin_layoutbox_menu_columnchoices_thumbs">
                                    <li>
                                        <img src="/public/img/admin/content/cols1_3.png" alt="3 columns"
                                             onclick="changeCurrentLayoutType('right,middle,left');">
                                    </li>
                                    <li>
                                        <img src="/public/img/admin/content/cols1_2left.png" alt="2 columns - Left"
                                             onclick="changeCurrentLayoutType('middle,left');">
                                    </li>
                                    <li>
                                        <img src="/public/img/admin/content/cols1_2right.png" alt="2 columns - Right"
                                             onclick="changeCurrentLayoutType('right,middle');">
                                    </li>
                                    <li>
                                        <img src="/public/img/admin/content/cols1_1.png" alt="1 columns"
                                             onclick="changeCurrentLayoutType('middle');">
                                    </li>
                                </ul>
                                <ul class="admin_layoutbox_menu_columnchoices_thumbs">
                                    <li>
                                        <img src="/public/img/admin/content/cols2_3.png" alt="3 columns"
                                             onclick="changeCurrentLayoutType('top,right,middle,left');">
                                    </li>
                                    <li>
                                        <img src="/public/img/admin/content/cols2_2left.png" alt="2 columns - Left"
                                             onclick="changeCurrentLayoutType('top,middle,left');">
                                    </li>
                                    <li>
                                        <img src="/public/img/admin/content/cols2_2right.png" alt="2 columns - Right"
                                             onclick="changeCurrentLayoutType('top,right,middle');">
                                    </li>
                                    <li>
                                        <img src="/public/img/admin/content/cols2_1.png" alt="1 columns"
                                             onclick="changeCurrentLayoutType('top,middle');">
                                    </li>
                                </ul>
                                <ul class="admin_layoutbox_menu_columnchoices_thumbs">
                                    <li>
                                        <img src="/public/img/admin/content/cols3_3.png" alt="3 columns"
                                             onclick="changeCurrentLayoutType('right,middle,left,bottom');">
                                    </li>
                                    <li>
                                        <img src="/public/img/admin/content/cols3_2left.png" alt="2 columns - Left"
                                             onclick="changeCurrentLayoutType('middle,left,bottom');">
                                    </li>
                                    <li>
                                        <img src="/public/img/admin/content/cols3_2right.png" alt="2 columns - Right"
                                             onclick="changeCurrentLayoutType('right,middle,bottom');">
                                    </li>
                                    <li>
                                        <img src="/public/img/admin/content/cols3_1.png" alt="1 columns"
                                             onclick="changeCurrentLayoutType('middle,bottom');">
                                    </li>
                                </ul>


                            </div>
                        </li>
                    </ul>
                </div>
                <button id="save_button" disabled="disabled" onclick="savePage();" type="button" class="btn btn-primary button-loading" data-loading-text="{{ "Saving..." | trans }}">{{ "Save" | trans }}</button>
            </div>
        </div>
        <div class="clearfix"></div>

        <div id="widget_list" class="admin_pages_widgets">
            <ul class="widgets">

            </ul>

        </div>

        <div id="global_placer" class="admin_pages_layout">


        </div>
        <div class="clear"></div>

    </div>
    <!--/row-->

{% endblock %}
