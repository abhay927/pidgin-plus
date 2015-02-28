<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:param name="screenshot.prefix"/>
    <xsl:param name="bugs.url"/>
    <xsl:param name="version"/>
    <xsl:template match="/">
        <xsl:text disable-output-escaping="yes"><![CDATA[<!DOCTYPE html>]]></xsl:text>
        <html><head>
            <meta charset="UTF-8"/>
            <title>Changelog &#x2013; Pidgin++</title>
            <style type="text/css">
                body {
                    font-family: "Segoe UI", "Ubuntu", "Open Sans";
                    max-width: 700px;
                    font-size: 0.9em;
                    color: #555;
                }

                .tag {
                    display: inline;
                    padding: 0px 3px;
                    border-radius: 2px;
                    font-size: 0.7em;
                    font-style: italic;
                    background-color: #eee;
                    color: #999;
                }

                a { text-decoration: none; }
                a:hover { text-decoration: underline; }

                #title       { display: none; }
                .translation { display: none; }
                .en_US       { display: inline; }

                ::-moz-selection { color: #f8f8f8; background-color: #555; }
                ::selection      { color: #f8f8f8; background-color: #555; }
                img              { margin: 10px; }
            </style>
            <xsl:text disable-output-escaping="yes"><![CDATA[<script type="text/javascript">
                function setDisplayForId(id, value) {
                    var element = document.getElementById(id);
                    if (!element)
                        return false;
                    element.style.display = value;
                    return true;
                }
                function setDisplayForClass(className, value) {
                    var elements = document.getElementsByClassName(className);
                    if (elements.length < 1)
                        return false;
                    for (var i = 0; i < elements.length; i++)
                        elements[i].style.display = value;
                    return true;
                }
                function parseParameters() {
                    window.parameters = {};
                    var pairs = window.location.search.slice(1).split("&");
                    pairs.forEach(function(pair) {
                        pair = pair.split("=");
                        var name = pair[0];
                        var value = pair[1] || "true";
                        var string = !value.match(/^(false|true|\d+|\d+\.\d+)$/);
                        window.parameters[name] = string? value : JSON.parse(value);
                    });
                }
                function getLanguage() {
                    var languageParameter = window.parameters["lang"];
                    var browserLanguage = (navigator.language || navigator.browserLanguage).replace('-', '_');
                    return languageParameter || browserLanguage;
                }
                function translate(language) {
                    var language = getLanguage();
                    if (language == "en_US")
                        return;
                    if (setDisplayForClass(language, "inline"))
                        setDisplayForClass("en_US", "none");
                }
                function showContent() {
                    if (window.parameters["full"]) {
                        setDisplayForId("title", "inline");
                        document.body.style.fontSize = "1.0em";
                    }
                }
                parseParameters();
            </script>]]></xsl:text>
        </head><body onLoad="showContent(); translate();">
            <div id="title">
                <h2 class="translation en_US">Changelog for Pidgin++</h2>
                <h2 class="translation pt_BR">Changelog do Pidgin++</h2>
            </div>

            <xsl:for-each select="changelog/version">
                <h4><xsl:value-of select="@id"/></h4>
                <ul><xsl:for-each select="change"><li>
                    <xsl:if test="@platform !=''">
                        <div class="tag"><xsl:value-of select="@platform"/></div>
                    </xsl:if>

                    <xsl:for-each select="@*[local-name() = 'description']"><span>
                        <xsl:attribute name="class">translation <xsl:value-of select="namespace-uri()"/></xsl:attribute>
                        <xsl:value-of select="."/>
                    </span></xsl:for-each>

                    <xsl:if test="@bug !=''">
                        <span>(<a target="_blank"><xsl:attribute name="href"><xsl:value-of select="$bugs.url"/>/<xsl:value-of select="@bug"/></xsl:attribute>#<xsl:value-of select="@bug"/></a>)</span>
                    </xsl:if>

                    <div><xsl:for-each select="screenshot"><span/>
                    <img><xsl:attribute name="src"><xsl:value-of select="$screenshot.prefix"/><xsl:value-of select="."/></xsl:attribute></img>
                    </xsl:for-each></div>
                </li></xsl:for-each></ul>
            </xsl:for-each>
        </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
