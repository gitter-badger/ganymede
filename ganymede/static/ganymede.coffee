# ganymede
#
# Hacking Jupyter's atmosphere
#
# Copyright (C) 2015 Stefan Zimmermann <zimmermann.code@gmail.com>
#
# ganymede is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ganymede is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with ganymede. If not, see <http://www.gnu.org/licenses/>.


class Ganymede
    constructor: (logo_src) ->
        metadata = window.IPython.notebook.metadata
        if not metadata.ganymede?
            metadata.ganymede = {}
        @metadata = metadata.ganymede

        $('#header').hide()
        @menubar = new Ganymede.MenuBar()
        @toolbar = new Ganymede.ToolBar()

        $('#ganymede').remove()
        @$ = $("""<div id="ganymede"></div>""")
        $('body').append @$

        @$.append @menubar.$
        @$.append @toolbar.$

        @logo = new Ganymede.Logo logo_src
        @logo.$.addClass 'ui-resizable-handle ui-resizable-se'
        @$.append @logo.$

        if not @metadata.height?
            @metadata.height = @logo.$.outerHeight true
        if not @metadata.width?
            @metadata.width = @logo.$.outerWidth true
        @$.height @metadata.height
        @$.width @metadata.width

        @$.resizable
            handles:
                se: @logo.$
            start: =>
                @preventClick = false
                @metadata.height = @$.height()
                @metadata.width = @$.width()
            resize: =>
                @resizing = true
                @preventClick = true
                @metadata.height = @$.height()
                @metadata.width = @$.width()
                @update()
            stop: =>
                @resizing = false
                @update()

        @preventClick = false
        @logo.$.click =>
            if @preventClick
                @preventClick = false
                return

            if @vertical
                @$.width if @$.width() != @metadata.width
                    @metadata.width
                else
                    @logo.$.outerWidth true
            else
                @$.height if @$.height() != @metadata.height
                    @metadata.height
                else
                    @logo.$.outerHeight true

        @console = new Ganymede.Console()

        $(window).on 'resize.ganymede', =>
            @update()
        @update()

    update: ->
        overHeight = @metadata.height - @$.height() + (@$.outerHeight true) \
            - $(window).height()
        if overHeight > 0
            @$.height @metadata.height - overHeight
        else if not @resizing
            @$.height @height
        overWidth = @metadata.width - @$.width() + (@$.outerWidth true) \
            - $(window).width()
        if overWidth > 0
            @$.width @metadata.width - overWidth
        else if not @resizing
            @$.width @width
        @horizontal = not (@vertical = @$.height() > @$.width())

        for $bar in [@menubar.$, @toolbar.$]
            $bar.toggleClass 'vertical', @vertical
            $bar.toggleClass 'horizontal', @horizontal

        $toolGroups = $('.btn-group', @toolbar.$)
        if @horizontal
            groupWidths = for group in $toolGroups
                $tools = $('.btn', group)
                width = 6 + $tools.length * ($tools.outerWidth true)
                $(group).css
                    width: width
                $(group).outerWidth true
            @toolbar.$.css
                width: groupWidths.reduce (l, r) -> l + r
        else
            $toolGroups.css
                width: ''
            @toolbar.$.css
                width: ''
        @

    unload: ->
        $origin = $('#menubar-container')
        $origin.append @menubar.unload().$
        $origin.append @toolbar.unload().$

        $checkpoint = @console.$checkpoint.prepend $('#notebook_name')
        $origin = $('#header-container')
        $origin.append $checkpoint
        $origin.append $('#kernel_logo_widget')
        $('#header').show()

        $(window).off 'resize.ganymede'
        @console.unload()
        @$.remove()
        @


class Ganymede.Logo
    constructor: (src) ->
        $('#ganymede-logo').remove()
        @$ = $("""<img id="ganymede-logo" src="#{src}" />""")


class Ganymede.MenuBar
    constructor: ->
        @$ = $('#menubar').detach()

    unload: ->
        $('.container-fluid > *:first', @$).after $('#kernel_indicator')
        $('.container-fluid > *:last', @$).before $('#notification_area')
        $('.kernel_indicator_name').show()
        @


class Ganymede.ToolBar
    constructor: ->
        @$ = $('#maintoolbar').detach()

    unload: ->
        $('.btn-group').css
            width: ''
        @$.css
            width: ''
        @


class Ganymede.Console
    constructor: ->
        metadata = window.IPython.notebook.metadata.ganymede
        if not metadata.console?
            metadata.console = {}
        @metadata = metadata.console

        @$ = $('#ipython-main-app')
        @$.append @$checkpoint = $('#save_widget')
        @$.append @$notifier = $('#notification_area')

        @$handles = {}
        for loc in ['sw', 's', 'se']
            id = "ganymede-console-handle-#{loc}"
            $('#' + id).remove()
            $handle = $("""<div id="#{id}">. . .</div>""").addClass """
                ganymede-console-handle btn btn-default
                ui-resizable-handle ui-resizable-#{loc}
                """
            @$.append @$handles[loc] = $handle

        if not @metadata.width?
            @metadata.width = @$.width()
        if not @metadata.height?
            @metadata.height = @$.height()

        if @metadata.left?
            @$.css
                left: @metadata.left
        else
            @metadata.left = @$.offset().left

        @$.resizable
            handles: @$handles
            start: (event) =>
                @preventClick = false
                @metadata.height = @$.height()
                @metadata.width = @$.width()
                @mouseX = event.pageX
                @offsetX = @$.offset().left
            resize: (event) =>
                @resizing = true
                @metadata.height = @$.height()
                @metadata.width = @$.width()
                if @$.data('ui-resizable').axis == 's'
                    @preventClick = true
                    @$.css
                        left: @metadata.left \
                            = @offsetX + event.pageX - @mouseX
                @update()
            stop: =>
                @resizing = false
                @update()

        @preventClick = false
        @$handles.s.click =>
            if @preventClick
                @preventClick = false
                return

            @$.toggleClass 'collapsed'
            if @$.hasClass 'collapsed'
                @$.css
                    top: 0
                    height: 0
            else
                @update()

        $tab = $('.ganymede-console-tab').detach()
        $('#ganymede-console-tabs').remove()
        @$tabs = $("""<ul id="ganymede-console-tabs"></ul>""")
        if not $tab.length
            $tab = $("""
                <li class="ganymede-console-tab">
                    <a href="#notebook"></a>
                </li>
                """)
            $indicator = $('#kernel_indicator')
            $('a', $tab).append $indicator
            $('.kernel_indicator_name', $indicator).hide()
            $indicator.prepend $('#notebook_name')
            $indicator.prepend $('#kernel_logo_widget')
        @$tabs.append $tab
        @$.prepend @$tabs
        @$.tabs()

        $('#notebook-container').on 'resize.ganymede-console', =>
            @updateOutputs()
        $(window).on 'resize.ganymede-console', =>
            @update()
        @update()

    update: ->
        @$.css
            top: top = @$tabs.outerHeight true
        overHeight = @metadata.height - @$.height() + (@$.outerHeight true) \
            + top + (@$handles.s.outerHeight true) - $(window).height()
        if overHeight > 0
            @$.height @metadata.height - overHeight
        else if not @resizing
            @$.height @metadata.height
        overWidth = @metadata.width - @$.width() + (@$.outerWidth true) \
            + @$.offset().left - $(window).width()
        if overWidth > 0
            @$.width @metadata.width - overWidth
        else if not @resizing
            @$.width @metadata.width
        @

    updateOutputs: ->
        $('.output_wrapper', @$).draggable
            handle: '.out_prompt_overlay'
            start: (event) =>
                $output = $(event.target)
                if not @$.hasClass 'collapsed'
                    @$.addClass 'collapsed'
                    @$.css
                        top: 0
                        height: 0
                $output.addClass 'ganymede'
                $output.css 'z-index', -1
                $outputs = $('.output_wrapper.ganymede').sort (l, r) ->
                    ($(l).css 'z-index') - ($(r).css 'z-index')
                z = -2 - $outputs.length
                $('body').css 'z-index', z - 1
                for output, index in $outputs
                    $(output).css 'z-index', z + index
                $output.css 'z-index', z + index
            stop: =>
                @$.removeClass 'collapsed'
                @update()
        @

    unload: ->
        $outputs = $('.output_wrapper', @$).removeClass 'ganymede'
        $outputs.css
            'z-index': ''
            position: ''
            top: ''
            left: ''

        @$tabs.remove()
        for loc, $handle of @$handles
            $handle.remove()

        @$.tabs 'destroy'
        @$.resizable 'destroy'
        @$.css
            position: ''
            left: ''
            top: ''
            width: ''
            height: ''

        $([window, '#notebook-container']).off 'resize.ganymede-console'
        @
