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
                body { font-family: "Segoe UI", "Ubuntu", "Open Sans"; font-size: 1.1em; color: #777; margin: 20px; max-width: 650px; }
            </style>
        </head><body>
            <h2><xsl:copy-of select="$title"/></h2>
            <p>This is a modified version of Pidgin, not supported by the official team. The following customizations have been made to original version <xsl:value-of select="$version"/>:</p>

            <ul><xsl:for-each select="changelog/change"><li>
                <xsl:value-of select="@description"/>
                <xsl:if test="@bug !=''">
                    (<a><xsl:attribute name="href"><xsl:value-of select="$bugs.url"/>/<xsl:value-of select="@bug"/></xsl:attribute>
                    #<xsl:value-of select="@bug"/></a>)
                </xsl:if>
            </li></xsl:for-each></ul>
        </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
