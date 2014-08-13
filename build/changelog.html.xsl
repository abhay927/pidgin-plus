<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:param name="bugs.url"/>
    <xsl:param name="version"/>
    <xsl:param name="version.custom"/>
    <xsl:variable name="title">Pidgin <xsl:value-of select="$version.custom"/></xsl:variable>
    <xsl:template match="/">
        <xsl:text disable-output-escaping="yes"><![CDATA[<!DOCTYPE html>]]></xsl:text>
        <html><head>
            <meta charset="UTF-8"/>
            <title><xsl:copy-of select="$title"/></title>
            <style type="text/css">
                img { margin: 10px; }
                body { font-family: "Segoe UI", "Ubuntu", "Open Sans"; font-size: 1.1em; color: #777; margin: 20px; max-width: 650px; }
                .translation { display: none; }
                .default { display: inline; }
            </style>
            <xsl:text disable-output-escaping="yes"><![CDATA[<script type="text/javascript">
                function setDisplay(className, value) {
                    var elements = document.getElementsByClassName(className);
                    if (elements.length < 1)
                        return false;
                    for (var i = 0; i < elements.length; i++)
                        elements[i].style.display = value;
                    return true;
                }
                function translate(language) {
                    if (setDisplay(language, "inline"))
                        setDisplay("default", "none");
                    else if (language != "")
                        document.location = "file://" + document.location.pathname;
                }
            </script>]]></xsl:text>
        </head><body onLoad="translate(window.location.search.slice(1));">
            <h2><xsl:copy-of select="$title"/></h2>
            <p class="translation default">This is a modified version of Pidgin, not supported by the official team. The following customizations have been made to original version <xsl:value-of select="$version"/>:</p>
            <p class="translation pt_BR">Esta é uma versão modificada do Pidgin, sem suporte do time oficial. As seguintes customizações foram aplicadas à versão original <xsl:value-of select="$version"/>:</p>

            <ul><xsl:for-each select="changelog/change"><li>
                <xsl:for-each select="@*[local-name() = 'description']"><span>
                    <xsl:attribute name="class">translation <xsl:value-of select="namespace-uri()"/></xsl:attribute>
                    <xsl:value-of select="."/>
                </span></xsl:for-each>

                <xsl:if test="@bug !=''">
                    (<a><xsl:attribute name="href"><xsl:value-of select="$bugs.url"/>/<xsl:value-of select="@bug"/></xsl:attribute>#<xsl:value-of select="@bug"/></a>)
                </xsl:if>

                <div><xsl:for-each select="screenshot">
                <img><xsl:attribute name="src"><xsl:value-of select="."/></xsl:attribute></img>
                </xsl:for-each></div>
            </li></xsl:for-each></ul>
        </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
