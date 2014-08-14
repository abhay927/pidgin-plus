<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:en="default">
    <xsl:param name="package.version"/>
    <xsl:param name="distribution"/>
    <xsl:param name="maintainer"/>
    <xsl:param name="date"/>

    <xsl:template match="/">
        <xsl:text>pidgin (</xsl:text><xsl:value-of select="$package.version"/><xsl:text>) </xsl:text><xsl:value-of select="$distribution"/><xsl:text>; urgency=low</xsl:text>
        <xsl:text>&#10;&#10;</xsl:text>

        <xsl:for-each select="changelog/platform[@id='all']/change">
            <xsl:text>  * </xsl:text><xsl:value-of select="@en:description"/><xsl:text>.</xsl:text>
            <xsl:if test="@bug !=''"><xsl:text> (#</xsl:text><xsl:value-of select="@bug"/><xsl:text>)</xsl:text></xsl:if>
            <xsl:text>&#10;</xsl:text>
        </xsl:for-each>
        <xsl:text>&#10;</xsl:text>

        <xsl:text> -- </xsl:text><xsl:value-of select="$maintainer" disable-output-escaping="yes"/>
        <xsl:text>  </xsl:text><xsl:value-of select="$date"/>
    </xsl:template>
</xsl:stylesheet>
