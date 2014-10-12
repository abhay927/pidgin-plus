<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:en-us="en_US">
    <xsl:param name="screenshots.url"/>
    <xsl:param name="bugs.url"/>

    <xsl:template match="/">
        <xsl:text># Changelog for Pidgin++</xsl:text><xsl:text>&#10;&#10;</xsl:text>

        <xsl:for-each select="changelog/version">
            <xsl:text>&#10;### </xsl:text><xsl:value-of select="@id"/><xsl:text>&#10;&#10;</xsl:text>

            <xsl:for-each select="change">
                <xsl:text>* </xsl:text><xsl:value-of select="@en-us:description"/>
                <xsl:if test="@bug !=''">
                    <xsl:text> ([#</xsl:text><xsl:value-of select="@bug"/><xsl:text>](</xsl:text>
                    <xsl:value-of select="$bugs.url"/><xsl:text>/</xsl:text><xsl:value-of select="@bug"/>
                    <xsl:text>))</xsl:text>
                </xsl:if>

                <xsl:if test="screenshot"><xsl:text>&#10;</xsl:text></xsl:if>
                <xsl:for-each select="screenshot">
                    <xsl:text>&#10;  ![](</xsl:text>
                    <xsl:value-of select="$screenshots.url"/><xsl:text>/</xsl:text><xsl:value-of select="."/>
                    <xsl:text>)</xsl:text>
                </xsl:for-each>
                <xsl:if test="following-sibling::*"><xsl:text>&#10;</xsl:text></xsl:if>

            </xsl:for-each>
            <xsl:if test="following-sibling::*"><xsl:text>&#10;</xsl:text></xsl:if>

        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
