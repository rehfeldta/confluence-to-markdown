class Page


  constructor: (fullPath, @formatter, @utils) ->
    @path = fullPath
    @init()


  init: () ->
    @fileName = @utils.getBasename @path
    @fileBaseName = @utils.getBasename @path, '.html'
    @filePlainText = @utils.readFile @path
    @$ = @formatter.load @filePlainText
    @content = @$.root()
    @heading = @getHeading()
    @fileNameNew = @getFileNameNew()
    @space = @utils.getBasename @utils.getDirname @path
    @spacePath = @getSpacePath()


  getSpacePath: () ->
    '../' + @utils.sanitizeFilename(@space) + '/' + @fileNameNew


  getFileNameNew: () ->
    return 'index.md' if @fileName == 'index.html'
    @utils.sanitizeFilename(@heading) + '.md'


  getHeading: () ->
    title = @content.find('title').text()
    if @fileName == 'index.html'
      title
    else
      indexName = @content.find('#breadcrumbs .first').text().trim()
      title.replace indexName + ' : ', ''


  ###*
  # Converts HTML file at given path to MD formatted text.
  # @return {string} Content of a file parsed to MD
  ###
  getTextToConvert: (pages) ->
    # TODO:Need to handle the below
    # - Add breadcrumb to index.md
    # - Remove "Expand Source" for scripts: e.g., Maintenance Mode
    # - Reformat hyperlinks in tables: eg., Refresh Database Password
    # - Table headers are being treated as the first row in markdown conversion instead of as headers: e.g., Refresh Database Password
    content = @formatter.getRightContentByFileName @content, @fileName
    content = @formatter.fixBreadcrumbs content, @heading
    content = @formatter.removeRelatedArticles content
    content = @formatter.removeBulletBlue content
    content = @formatter.removeDownloadAll content
    content = @formatter.cleanImageAttachments content
    content = @formatter.fixHeadline content
    content = @formatter.fixIcon content
    content = @formatter.fixEmptyLink content
    content = @formatter.fixEmptyHeading content
    content = @formatter.fixPreformattedText content
    content = @formatter.fixImageWithinSpan content
    content = @formatter.removeArbitraryElements content
    content = @formatter.fixArbitraryClasses content
    content = @formatter.fixAttachmentWraper content
    content = @formatter.fixPageLog content
    content = @formatter.fixLocalLinks content, @space, pages
    content = @formatter.addPageHeading content, @heading
    @formatter.getHtml content


module.exports = Page
