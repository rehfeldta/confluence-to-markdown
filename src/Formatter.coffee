class Formatter

  ###*
  # @param {cheerio} _cheerio Required lib
  # @param {Utils} utils My lib
  # @param {Logger} logger My lib
  ###
  constructor: (@_cheerio, @utils, @logger) ->


  ###*
  # @param {string} text Content of a file
  # @return {cheerio obj} Root object of a text
  ###
  load: (text) ->
    @_cheerio.load text


  ###*
  # @param {cheerio obj} $content Content of a file
  # @return {string} Textual representation of a content
  ###
  getText: ($content) ->
    $content.text()


  ###*
  # @param {cheerio obj} $content Content of a file
  # @return {string} HTML representation of a content
  ###
  getHtml: ($content) ->
    $ = @_cheerio
    contentHtml = ''
    $content.each (i, el) =>
      contentHtml += $(el).html()
    contentHtml


  ###*
  # The right content is selected based on the filename given.
  # Actual content of a page is placed elsewhere for index.html and other pages.
  # @see load() You need to load the content first.
  # @param {string} fileName Name of a file
  ###
  getRightContentByFileName: ($content, fileName) ->
    if fileName == 'index.html'
      $content.find('#content')
        .find('#main-content>.confluenceTable').remove().end() # Removes arbitrary table located on top of index page
    else
      selector = [
        '#breadcrumb-section' # Include breadcrumb section
        '#main-content'
        '.pageSection.group:has(.pageSectionHeader>#attachments)'
        '.pageSection.group:has(.pageSectionHeader>#comments)'
      ]
      $content.find selector.join ', '

  ###*
  # Transforms the breadcrumb list into a paragraph element with Markdown links, prepending a custom crumb.
  # @param {cheerio obj} $content Content of a file
  # @return {cheerio obj} Updated content with breadcrumbs as a paragraph
  ###
  fixBreadcrumbs: ($content, customCrumb = 'Home') ->
    $ = @_cheerio
    breadcrumbs = $content.find('#breadcrumb-section #breadcrumbs')
    breadcrumbMarkdown = "<a href=\"../README.md\">Home</a> > " # Prepend custom crumb
    breadcrumbs.find('li').each (i, el) =>
      link = $(el).find('a')
      href = link.attr('href')
      text = link.text()
      breadcrumbMarkdown += "<a href=\"#{href}\">#{text}</a> > "
    breadcrumbMarkdown = breadcrumbMarkdown.trim().slice(0, -2) # Remove trailing arrow
    breadcrumbParagraph = $("<p id=\"breadcrumbs\">#{breadcrumbMarkdown}</p>")
    breadcrumbs.replaceWith breadcrumbParagraph # Replace breadcrumbs with formatted paragraph
    $content

  ###*
  # Removes <h2> elements with an id ending in "-Relatedarticles" and the subsequent <ul> with class "content-by-label".
  # @param {cheerio obj} $content Content of a file
  # @return {cheerio obj} Updated content without the specified <h2> and <ul> elements
  ###
  removeRelatedArticles: ($content) ->
    $ = @_cheerio
    $content.find('h2').each (i, el) =>
      if $(el).attr('id')?.endsWith('-Relatedarticles')
        nextUl = $(el).next('ul.content-by-label')
        @logger.debug("Removing related articles")
        $(el).remove() # Remove the <h2> element
        nextUl.remove() # Remove the subsequent <ul> element
    $content

    ###*
  # Removes <img> elements with the bullet_blue.gif src attribute.
  # @param {cheerio obj} $content Content of a file
  # @return {cheerio obj} Updated content without the specified <img> elements
  ###
  removeBulletBlue: ($content) ->
    $ = @_cheerio
    $content.find('img').each (i, el) =>
      if $(el).attr('src') == 'images/icons/bullet_blue.gif'
        @logger.debug("Removing bullet_blue icon")
        $(el).remove()
    $content

  
  ###*
  # Removes download all button.
  # @param {cheerio obj} $content Content of a file
  # @return {cheerio obj} Updated content without the specified <img> elements
  ###
  removeDownloadAll: ($content) ->
    $ = @_cheerio
    $content.find('a').each (i, el) =>
      if $(el).attr('class') == 'download-all-link'
        @logger.debug("Removing download all icon")
        $(el).remove()
    $content

  # TODO: This doesn't work. Try to fix if this strategy seems useful
  ###*
  # Removes <a> elements in the attachments section if their href matches any img src in the main content,
  # along with the preceding <img> and <br> elements.
  # @param {cheerio obj} $content Content of a file
  # @return {cheerio obj} Updated content with cleaned attachments section
  ###
  cleanImageAttachments: ($content) ->
    $ = @_cheerio

    # Collect all image sources from the main content
    imageSrcs = []
    @logger.debug("Images")
    $content.find('img').each (i, el) =>
      @logger.debug($(el).attr('src'))
      imageSrcs.push($(el).attr('src'))

    # Find the attachments section
    attachmentsSection = $content.find('.pageSection.group').filter (i, el) ->
      $(el).find('h2#attachments').length > 0

    # Within the attachments section, find the greybox div
    greybox = attachmentsSection.find('.greybox')

    # Remove <a> elements in the greybox if their href matches any image src
    @logger.debug("Attachments")
    greybox.find('a').each (i, el) =>
      @logger.debug($(el).attr('href'))
      href = $(el).attr('href')
      if href in imageSrcs
        # Remove the <a> element and its associated <img> and <br> elements
        $(el).prev('img').remove() # Remove the preceding <img>
        $(el).next('br').remove()  # Remove the following <br>
        $(el).remove()             # Remove the <a> element

    $content


  ###*
  # Removes span inside of a h1 tag.
  # @param {cheerio obj} $content Content of a file
  # @return {cheerio obj} Cheerio object
  ###
  fixHeadline: ($content) ->
    @_removeElementLeaveText $content, 'span.aui-icon'


  addPageHeading: ($content, headingText) ->
    $ = @_cheerio
    h1 = $('<h1>').text headingText
    $content.first().prepend h1
    $content


  ###*
  # Removes redundant icon
  # @param {cheerio obj} $content Content of a file
  # @return {cheerio obj} Cheerio object
  ###
  fixIcon: ($content) ->
    @_removeElementLeaveText $content, 'span.aui-icon'


  ###*
  # Removes empty link
  # @param {cheerio obj} $content Content of a file
  # @return {cheerio obj} Cheerio object
  ###
  fixEmptyLink: ($content) ->
    $ = @_cheerio
    $content
      .find('a').each (i, el) =>
        if (
          $(el).text().trim().length == 0 \
          and $(el).find('img').length == 0
        )
          $(el).remove()
      .end()


  ###*
  # Removes empty heading
  # @param {cheerio obj} $content Content of a file
  # @return {cheerio obj} Cheerio object
  ###
  fixEmptyHeading: ($content) ->
    $ = @_cheerio
    $content
      .find(':header').each (i, el) =>
        if $(el).text().trim().length == 0
          $(el).remove()
      .end()


  ###*
  # Gives the right class to syntaxhighlighter
  # @param {cheerio obj} $content Content of a file
  # @return {cheerio obj} Cheerio object
  ###
  fixPreformattedText: ($content) ->
    $ = @_cheerio
    $content
      .find('pre').each (i, el) =>
        data = $(el).data('syntaxhighlighterParams')
        $(el).attr('style', data)
        styles = $(el).css()
        brush = styles?.brush
        $(el).removeAttr 'class'
        $(el).addClass brush if brush
      .end()


  ###*
  # Fixes 'p > a > span > img' for which no image was created.
  # @param {cheerio obj} $content Content of a file
  # @return {cheerio obj} Cheerio object
  ###
  fixImageWithinSpan: ($content) ->
    $ = @_cheerio
    $content
      .find('span:has(img)').each (i, el) =>
        if $(el).text().trim().length == 0
          $(el).replaceWith($(el).html())
      .end()


  removeArbitraryElements: ($content) ->
    @_removeElementLeaveText $content, 'span, .user-mention'


  ###*
  # Removes arbitrary confluence classes.
  # @param {cheerio obj} $content Content of a file
  # @return {cheerio obj} Cheerio object
  ###
  fixArbitraryClasses: ($content) ->
    $content
      .find('*').removeClass (i, e) ->
        (
          e.match(/(^|\s)(confluence\-\S+|external-link|uri|tablesorter-header-inner|odd|even|header)/g) || []
        ).join ' '
      .end()


  ###*
  # Removes arbitrary confluence elements for attachments.
  # @param {cheerio obj} $content Content of a file
  # @return {cheerio obj} Cheerio object
  ###
  fixAttachmentWraper: ($content) ->
    $content
      .find('.attachment-buttons').remove().end() # action buttons for attachments
      .find('.plugin_attachments_upload_container').remove().end() # dropbox for uploading new files
      .find('table.attachments.aui').remove().end() # overview table with useless links


  ###*
  # Removes arbitrary confluence elements for page log.
  # @param {cheerio obj} $content Content of a file
  # @return {cheerio obj} Cheerio object
  ###
  fixPageLog: ($content) ->
    $content
      .find('[id$="Recentspaceactivity"], [id$=Spacecontributors]').parent().remove()
      .end().end()

  # TODO: This is not correctly fixing local links. Links should drop everything prior to the article name and replace all white space characters with "_"
  # See: 
  ###*
  # Changes links to local HTML files to generated MD files.
  # @param {cheerio obj} $content Content of a file
  # @param {string} cwd Current working directory (where HTML file reside)
  # @return {cheerio obj} Cheerio object
  ###
  fixLocalLinks: ($content, space, pages) ->
    $ = @_cheerio
    $content
      .find('a').each (i, el) =>
        href = $(el).attr 'href'
        if href == undefined
          text = $(el).text()
          $(el).replaceWith text
          @logger.debug 'No href for link with text "#{text}"'
        else if $(el).hasClass 'createlink'
          $(el).replaceWith $(el).text()
        else if pageLink = @utils.getLinkToNewPageFile href, pages, space
          $(el).attr 'href', pageLink
      .end()


  ###*
  # @param {array} indexHtmlFiles Relative paths of index.html files from all parsed Confluence spaces
  # @return {cheerio obj} Cheerio object
  ###
  createListFromArray: (itemArray) ->
    $ = @_cheerio.load '<ul>'
    $ul = $('ul')
    for item in itemArray
      $a = $('<a>').attr('href', item).text item.replace '/index', ''
      $li = $('<li>')
      $li.append $a
      $ul.append $li
    $ul.end()


  ###*
  # Removes element by selector and leaves only its text content
  # @param {cheerio obj} $content Content of a file
  # @param {string} selector Selector of an element
  # @return {cheerio obj} Cheerio object
  ###
  _removeElementLeaveText: ($content, selector) ->
    $ = @_cheerio
    $content
      .find(selector).each (i, el) =>
        $(el).replaceWith $(el).text()
      .end()


module.exports = Formatter
