define [
  'jquery'
  'jst/jquery/ModuleSequenceFooter'
  'underscore'
  'i18n!sequence_footer'
  'jquery.ajaxJSON'
], (jQuery, template, _, I18n) ->
  # Summary
  #   Creates a new ModuleSequenceFooter so clicking to see the next item in a module
  #   can be done easily. 
  #
  #   Required options: 
  #     assetType : string
  #     assetID   : integer
  #
  #   ie: 
  #     $('#footerDiv').moduleSequenceFooter({
  #       assetType: 'Assignment'
  #       assetID: 1
  #       courseID: 25
  #     })
  #
  #   You can optionaly set options on the prototype for all instances of this plugin by default
  #   by doing: 
  #
  #   $.fn.moduleSequenceFooter.options = {
  #     assetType: 'Assigbnment'
  #     assetID: 1
  #     courseID: 25
  #   }
  ((($, window, document, template) ->

    $.fn.moduleSequenceFooter = (options={}) ->

      # You must pass in a assetType and assetId or we throw an error.
      unless options.assetType and options.assetID
        throw 'Option must be set with assetType and assetID'
        return

      # After fetching, @msfInstance will have the following
      # @hide: bool
      # @previous: Object
      # @next : Object
      @msfInstance = new $.fn.moduleSequenceFooter.MSFClass options
      @msfInstance.fetch().done =>
        if @msfInstance.hide
          @hide()
          return 

        @html template(
          previous: @msfInstance.previous
          next: @msfInstance.next
        )
        @show()

      this

    $.fn.moduleSequenceFooter.MSFClass = class ModuleSequenceFooter

      # Icon class map used to determin which icon class should be placed
      # on a tooltip
      # @api private

      iconClasses: 
        'ModuleItem'   : "icon-module"
        'File'         : "icon-download"
        'Page'         : "icon-document"
        'Discussion'   : "icon-discussion"
        'Assignment'   : "icon-assignment"
        'Quiz'         : "icon-quiz"
        'ExternalTool' : "icon-link"

      # Sets up the class variables and generates a url. Fetch should be
      # called somewhere else to set up the data.
       
      constructor: (options) ->
        @courseID = options?.courseID || ENV?.course_id
        @assetID = options?.assetID
        @assetType = options?.assetType
        @location = options?.location || document.location
        @previous = {}
        @next = {}

        @url = "/api/v1/courses/#{@courseID}/module_item_sequence"

      getQueryParams: (qs) ->
        qs = qs.split("+").join(" ")
        params = {}
        re = /[?&]?([^=]+)=([^&]*)/g

        while (tokens = re.exec(qs))
            params[decodeURIComponent(tokens[1])] = decodeURIComponent(tokens[2])
        
        params

      # Retrieve data based on the url, asset_type and asset_id. @success is called after a 
      # fetch is finished. This will then setup data to be used elsewhere.
      # @api public

      fetch: ->
        params = @getQueryParams(@location.search)
        if params.module_item_id
          $.ajaxJSON @url, 'GET', {asset_type: 'ModuleItem', asset_id: params.module_item_id}, @success, null, {}
        else
          $.ajaxJSON @url, 'GET', {asset_type: @assetType, asset_id: @assetID}, @success, null, {}

      # Determines if the data retrieved should be used to generate a buttom bar or hide it. We 
      # can only have 1 item in the data set for this to work else we hide the sequence bar. 
      # # @api private

      success: (data) => 
        @modules = data.modules

        # Currently only supports 1 item in the items array
        unless data?.items?.length == 1
          @hide = true 
          return

        @item = data.items[0]
        # Show the buttons if they aren't null
        @buildNextData() if (@next.show = @item.next) 
        @buildPreviousData() if (@previous.show = @item.prev)

      # Each button needs to build a data that the handlebars template can use. For example, data for
      # each button could look like this: 
      #  @previous = previous: {
      #     show: true
      #     url: http://foobar.baz
      #     tooltip: <strong>Next Module:</strong> <br> Going to the fair
      #   }
      #
      # If the previous item is in another module, then the module ids won't be the same and we need
      # to display the module name instead of the item title.
      # @api private

      buildPreviousData: -> 
        @previous.url = @item.prev.html_url

        if @item.current.module_id == @item.prev.module_id
          @previous.tooltip = "<i class='#{@iconClasses[@item.prev.type]}'></i> #{@item.prev.title}"
        else # module id is different
          module = _.find @modules, (m) => m.id == @item.prev.module_id
          @previous.tooltip = "<strong style='float:left'>#{I18n.t('prev_module', 'Previous Module')}#{I18n.t('prev_colon', ':')}</strong> <br> #{module.name}"

      # Each button needs to build a data that the handlebars template can use. For example, data for
      # each button could look like this: 
      #  @next = next: {
      #     show: true
      #     url: http://foobar.baz
      #     tooltip: <strong>Next Module:</strong> <br> Going to the fair
      #   }
      #
      # If the next item is in another module, then the module ids won't be the same and we need
      # to display the module name instead of the item title.
      # @api private

      buildNextData: ->
        @next.url = @item.next.html_url

        if @item.current.module_id == @item.next.module_id
          @next.tooltip = "<i class='#{@iconClasses[@item.next.type]}'></i> #{@item.next.title}"
        else # module id is different
          module = _.find @modules, (m) => m.id == @item.next.module_id
          @next.tooltip = "<strong style='float:left'>#{I18n.t('next_module', 'Next Module')}#{I18n.t('next_colon', ':')}</strong> <br> #{module.name}"


  ))( jQuery, window, document, template)
