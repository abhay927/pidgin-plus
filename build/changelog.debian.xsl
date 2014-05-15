<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:param name="version.custom"/>
    <xsl:param name="maintainer"/>
    <xsl:param name="date"/>

    <xsl:template match="/">
        <xsl:text>pidgin (VERSION+</xsl:text><xsl:value-of select="$version.custom"/><xsl:text>) DISTRIBUTION; urgency=low</xsl:text>
        <xsl:text>&#10;&#10;</xsl:text>

        <xsl:for-each select="changelog/change">
            <xsl:text>  * </xsl:text><xsl:value-of select="@description"/><xsl:text>.</xsl:text>
            <xsl:if test="@bug !=''"><xsl:text> (#</xsl:text><xsl:value-of select="@bug"/><xsl:text>)</xsl:text></xsl:if>
            <xsl:text>&#10;</xsl:text>
        </xsl:for-each>
        <xsl:text>&#10;</xsl:text>

        <xsl:text> -- </xsl:text><xsl:value-of select="$maintainer" disable-output-escaping="yes"/>
        <xsl:text>  </xsl:text><xsl:value-of select="$date"/>
    </xsl:template>
</xsl:stylesheet>
