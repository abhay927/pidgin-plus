<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:param name="bugs.url"/>
    <xsl:param name="version"/>
    <xsl:variable name="title">Pidgin++</xsl:variable>
    <xsl:template match="/">
        <xsl:text disable-output-escaping="yes"><![CDATA[<!DOCTYPE html>]]></xsl:text>
        <html><head>
            <meta charset="UTF-8"/>
            <title><xsl:copy-of select="$title"/></title>
            <style type="text/css">
                body {
                    font-family: "Segoe UI", "Ubuntu", "Open Sans";
                    margin: 20px;
                    max-width: 700px;
                    color: #555;
                }

                h4 { margin-bottom: 0px; }
                a { text-decoration: none; }
                a:hover { text-decoration: underline; }

                .translation { display: none; }
                .default     { display: inline; }

                ::-moz-selection { color: #f8f8f8; background-color: #555; }
                ::selection      { color: #f8f8f8; background-color: #555; }
                img              { margin: 10px; }
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
            <p class="translation default">Welcome to Pidgin++, version <i><xsl:value-of select="$version"/></i>. This is an improved version of Pidgin, with the customizations below applied to original version. For questions please visit <a target="_blank" href="https://answers.launchpad.net/pidgin++">the support area</a>.</p>
            <p class="translation pt_BR">Bem-vindo ao Pidgin++, versão <i><xsl:value-of select="$version"/></i>. Esta é uma versão melhorada do Pidgin, com as customizações abaixo aplicadas à versão original. Para perguntas por favor visite a <a target="_blank" href="https://answers.launchpad.net/pidgin++">área de suporte</a>.</p>

            <xsl:for-each select="changelog/platform">
                <h4><xsl:for-each select="@*[local-name() = 'description']"><span>
                    <xsl:attribute name="class">translation <xsl:value-of select="namespace-uri()"/></xsl:attribute>
                    <xsl:value-of select="."/>
                </span></xsl:for-each></h4>

                <ul><xsl:for-each select="change"><li>
                    <xsl:for-each select="@*[local-name() = 'description']"><span>
                        <xsl:attribute name="class">translation <xsl:value-of select="namespace-uri()"/></xsl:attribute>
                        <xsl:value-of select="."/>
                    </span></xsl:for-each>

                    <xsl:if test="@bug !=''">
                        (<a target="_blank"><xsl:attribute name="href"><xsl:value-of select="$bugs.url"/>/<xsl:value-of select="@bug"/></xsl:attribute>#<xsl:value-of select="@bug"/></a>)
                    </xsl:if>

                    <div><xsl:for-each select="screenshot"><span/>
                    <img><xsl:attribute name="src"><xsl:value-of select="."/></xsl:attribute></img>
                    </xsl:for-each></div>
                </li></xsl:for-each></ul>
            </xsl:for-each>
        </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
