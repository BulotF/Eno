<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:xf="http://www.w3.org/2002/xforms" xmlns:fr="http://orbeon.org/oxf/xml/form-runner"
    xmlns:xxf="http://orbeon.org/oxf/xml/xforms" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ev="http://www.w3.org/2001/xml-events">

    <!-- Fichier de propriétés eno -->
    <xsl:param name="fichier-proprietes"/>
    <xsl:variable name="proprietes" select="doc($fichier-proprietes)"/>
    <xsl:variable name="apos">'</xsl:variable>

    <!-- ****** Paramètres de la transformation ***** -->

    <!-- id de l'élément racine des binds de l'instance du formulaire.-->
    <xsl:param name="binds" select="'fr-form-instance-binds'"/>
    <!-- Liste des contrôles sur lesquels il faut ajouter les propriétés readonly.
        Attention, il s'agit des local-name() (sans les préfixes) et la chaîne utilise '#' comme séparateur et doit commencer et terminer par '#' (-->
    <xsl:param name="listeTypeControleReadOnly" select="'#input#number#textarea#'"/>
    <!-- Liste fournissant les tableaux pour lesquels il faut ajouter un bouton readOnly/readWrite (pour des champs pré-remplis dont on souhaite décourager le remplissage), 
        ainsi que pour chaque tableau les rang des colonnes pour lesquelles il faut laisser les contrôles en mode readWrite (champs non pré-remplis).
        Cette information pourrait être récupéré du DDI, si on est en mesure d'identifier quels sont les contrôles pré-remplis.
    La liste doit être de la forme : 
    #idTableau1$-rangColonneTableau1-rangColonneTableau1-#idTableau2$rangColonneTableau2-...# 
    (séparateur '#' entre les groupes de tableaux, séparateur '$' entre l'id du tableau et le rang des colonnes, séparateur '-' entre les range de colonnes, chaque liste doit commencer et terminer par son séparateur)
    Attention, le rang d'une colonne ne doit prendre en compte que les td (simplifie le calcul de colonne)-->
    <xsl:param name="tableauxReadOnly" select="'#DARES-ACEMO-QG-3-1$-3-4-#'"/>

    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
    <xsl:strip-space elements="*"/>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Template de racine, on applique les templates de tous les enfants</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:apply-templates select="*"/>
    </xsl:template>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Template de base pour tous les éléments et tous les attributs, on recopie
                simplement en sortie</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
<!--
    <xsl:template match="form[parent::xf:instance[@id='fr-form-instance']]/stromae/util">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="titre-formulaire"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="xhtml:div[@class='perso-formulaire']">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xf:output id="titre-formulaire" bind="titre-formulaire-bind"
                xxf:order="label control hint help alert" class="titre_enquete">
                <xf:label ref="$form-resources/titre-formulaire/label" mediatype="text/html"/>
            </xf:output>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="resource[ancestor::xf:instance[@id='fr-form-resources']]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <titre-formulaire>
                <label><xsl:value-of select="concat('&lt;p&gt;&lt;span class=''gros''&gt;DARES&lt;/span&gt; Direction de l''animation
                    de la recherche, des études et des statistiques&lt;/p&gt;&lt;p&gt;',//xhtml:title,'&lt;/p&gt;')"/></label>
            </titre-formulaire>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>-->

    <!-- Template qui calcul la liste des binds ReadOnly et déclenche le mode addReadOnly pour les binds enfants.
        Structure de binds d'Eno du type :
        <xf:bind>  <- bind de l'instance principale
            <xf:bind> <- binds des sections
                <xf:bind> <- binds des controles
    -->
    
    <xsl:template match="xf:bind[@id=$binds]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!--<xf:bind id="titre-formulaire-bind" name="titre-formulaire" ref="stromae/util/titre-formulaire"/>-->
            <xsl:element name="xf:bind">
                <xsl:attribute name="id" select="string('titre-formulaire-bind')"/>
                <xsl:attribute name="name" select="string('titre-formulaire')"/>
                <xsl:attribute name="ref" select="string('stromae/util/titre-formulaire')"/>
            </xsl:element>
            <xsl:apply-templates select="*" mode="addReadOnly">
                <!-- On passe en paramètre la liste des binds pour lesquels il faut ajouter une propriété readOnly -->
                <xsl:with-param name="listeIdBindsReadOnly" as="xs:string" tunnel="yes">
                    <!-- On construit la liste des id des binds à partir d'un template spécifique. -->
                    <xsl:call-template name="bindsReadOnly"/>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <!-- Template par défaut du mode addReadOnly, on applique le template par défaut. -->
    <xsl:template match="*" mode="addReadOnly">
        <xsl:apply-templates select="."/>
    </xsl:template>

    <!-- Template pour les binds de deuxième niveau, on propage le mode addReadOnly  -->
    <xsl:template match="xf:bind[@id=$binds]/xf:bind[xf:bind]" mode="addReadOnly">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="*" mode="addReadOnly"/>
        </xsl:copy>
    </xsl:template>

    <!-- En mode addReadOnly, on test chaque binds pour définir s'il faut ou non lui ajouter une propriété. -->
    <xsl:template match="xf:bind[not(xf:bind)]" mode="addReadOnly">
        <xsl:param name="listeIdBindsReadOnly" as="xs:string" tunnel="yes"/>
        <xsl:choose>
            <xsl:when test="contains($listeIdBindsReadOnly,concat('#',@id,'#'))">
                <xsl:variable name="ligneTableau" select="//xhtml:tr[.//*[@bind=current()/@id]]"/>
                <xsl:variable name="rangColonne"
                    select="count($ligneTableau/preceding-sibling::xhtml:tr) + 1"/>
                <xsl:variable name="indexTableau"
                    select="count($ligneTableau/ancestor::xhtml:table/preceding::xhtml:table[contains($tableauxReadOnly,concat('#',@name,'$'))]) + 1"/>
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                    <xsl:attribute name="readonly"
                        select="concat('instance(''acemotrim-util'')/tableau',$indexTableau,'-edit/*[',$rangColonne,']=''0''')"/>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Template qui récupère la liste des ids des binds associés à un champ modifiable d'un tableau complexe.
        Cette liste permettra d'ajouter aux binds correspondants des propriétés (readonly).
-->
    <xsl:template name="bindsReadOnly" as="xs:string">
        <!-- Récupération des ids des binds associés aux contrôles à mettre en mode ReadOnly par défaut (= quand ils sont pré-remplies) -->
        <xsl:variable name="controlesReadOnly" as="xs:string*">
            <!-- On récupère chaque tableau concernés à partir de la liste passée en paramètre. -->
            <xsl:for-each select="//xhtml:table[contains($tableauxReadOnly,concat('#',@name,'$'))]">
                <!-- On extrait la liste des colonnes dont les contrôles doivent rester en ReadWrite. -->
                <xsl:variable name="RangsColonnexxx"
                    select="substring-after($tableauxReadOnly,concat('#',@name,'$'))"/>
                <xsl:variable name="RangsColonne" select="substring-before($RangsColonnexxx,'#')"/>
                <!-- On isole chaque ligne pour pouvoir compter la position des éléments au sein de la ligne. -->
                <xsl:for-each select="xhtml:tbody/xhtml:tr">
                    <!-- Pour chaque td du tableau, on test la colonne et si elle n'est pas à omettre (paramètres), on renvoie les binds -->
                    <xsl:for-each select="xhtml:td">
                        <xsl:if test="not(contains($RangsColonne,concat('-',position(),'-')))">
                            <!-- On renvoie l'id du bind pour que le comportement readOnly lui soit ajouté. -->
                            <xsl:sequence
                                select="string-join(*[contains($listeTypeControleReadOnly,concat('#',local-name(),'#'))]/@bind,'#')"
                            />
                        </xsl:if>
                    </xsl:for-each>
                </xsl:for-each>

            </xsl:for-each>
        </xsl:variable>
        <!-- Constitution d'une chaîne de caractères avec les id des binds pour tester (on ajoute un séparateur en début et en fin de chaîne) -->
        <xsl:value-of select="concat('#',string-join($controlesReadOnly,'#'),'#')"/>
    </xsl:template>

    <!-- Template qui ajoute les boutons pour rendre éditable une ligne de 'tableauComplexe' -->
    <xsl:template
        match="xhtml:table[contains($tableauxReadOnly,concat('#',@name,'$'))]/xhtml:tbody/xhtml:tr">
        <!--        <xsl:template match="xhtml:table[contains(@class,'tableauComplexe')]/xhtml:tbody/xhtml:tr">-->
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates/>
            <xsl:variable name="index" select="count(preceding-sibling::xhtml:tr)+1"/>
            <xsl:variable name="indexTableau"
                select="count(ancestor::xhtml:table/preceding::xhtml:table[contains($tableauxReadOnly,concat('#',@name,'$'))]) + 1"/>
            <xsl:variable name="idRoot" select="concat(ancestor::xhtml:table/@name,'-edit',$index)"/>
            <xsl:element name="xhtml:td">
                <xsl:attribute name="align" select="string('center')"/>
                <!--                <xf:trigger id="{concat($idRoot,'-control')}" bind="{concat($idRoot,'-bind')}">-->
                <xsl:element name="xf:trigger">
                    <xsl:attribute name="id" select="concat($idRoot,'-control')"/>
                    <xsl:element name="xf:label">
                        <xsl:element name="xhtml:img">
                            <xsl:attribute name="src">
                                <xsl:value-of select="concat('/',$proprietes//images/dossier,'/',$proprietes//images/modifier)"/>
                            </xsl:attribute>
                            <xsl:attribute name="alt">
                                <xsl:value-of select="string('modifier')"/>
                            </xsl:attribute>
                            <xsl:attribute name="class">
                                <xsl:value-of select="string('boutonModifCase')"/>
                            </xsl:attribute>
                        </xsl:element>
                    </xsl:element>
<!--                    <xf:setvalue ev:event="DOMActivate"
                        ref="instance('acemotrim-util')/tableau{$indexTableau}-edit/*[{$index}]"
                        value="if(instance('acemotrim-util')/tableau{$indexTableau}-edit/*[{$index}]='1') then (0) else(1)"
                    />
-->                    <xsl:element name="xf:setvalue">
                        <xsl:attribute name="ev:event" select="string('DOMActivate')"/>
                        <xsl:attribute name="ref" select="concat('instance(',$apos,'acemotrim-util',$apos,')/tableau',$indexTableau,'-edit/*[',$index,']')"/>
                        <xsl:attribute name="value"
                            select="concat('if(instance(',$apos,'acemotrim-util',$apos,')/tableau',$indexTableau,'-edit/*[',$index,']=',$apos,'1',$apos,') then (0) else(1)')"/>
                    </xsl:element>
                </xsl:element>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template
        match="xhtml:table[contains($tableauxReadOnly,concat('#',@name,'$'))]/xhtml:thead/xhtml:tr[1]">
        <xsl:variable name="nbLignes" select="count(parent::xhtml:thead/xhtml:tr)"/>
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
            <xsl:element name="xhtml:th">
                <xsl:attribute name="rowspan"><xsl:value-of select="$nbLignes"/></xsl:attribute>
                <xsl:attribute name="colspan"><xsl:value-of select="string('1')"/></xsl:attribute>
                <!--<xhtml:p class="colonneE"><xhtml:a href="#ftn11">E</xhtml:a></xhtml:p>-->
                <xsl:element name="xhtml:p">
                    <xsl:attribute name="class" select="string('colonneE')"/>
                    <xsl:element name="xhtml:a">
                        <xsl:attribute name="href" select="string('#ftn11')"/>
                        <xsl:value-of select="'E'"/>
                    </xsl:element>                    
                </xsl:element>
            </xsl:element>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="xf:model[@id='fr-form-model']">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
            <xsl:element name="xf:instance">
                <xsl:attribute name="id" select="string('acemotrim-util')"/>
            
                <xsl:element name="util">
                    <xsl:for-each select="//xhtml:table[contains($tableauxReadOnly,concat('#',@name,'$'))]">
                        <xsl:element name="tableau{current()/position()}-edit">
                            <xsl:for-each select="xhtml:tbody/xhtml:tr">
                                <xsl:element name="ligne">
                                    <xsl:value-of select="string('0')"/>
                                </xsl:element>
                                <!--<ligne>0</ligne>-->
                            </xsl:for-each>
                        </xsl:element>
                    </xsl:for-each>
                </xsl:element>
            </xsl:element>
        </xsl:copy>
    </xsl:template>


    <!-- passage en non dynamique des rosters -->

    <xsl:template match="xf:instance[@id='fr-form-instance']//*[ends-with(name(),'-Container')]">
        <xsl:apply-templates select="node()/node()"/>
    </xsl:template>

    <xsl:template match="xf:instance[@id='fr-form-instance']//*[ends-with(name(),'-Count') or ends-with(name(),'-AddLine')]"/>
    
    <xsl:template match="xf:instance[@id='fr-form-loop-model']/LoopModels">
        <xsl:copy/>
    </xsl:template>
    
    <xsl:template match="xf:bind[@id='fr-form-instance-binds']//xf:bind[ends-with(@id,'-Container-bind')]">
        <xsl:apply-templates select="node()"/>
    </xsl:template>

    <xsl:template match="xf:bind[@id='fr-form-instance-binds']//xf:bind[ends-with(@id,'-addline-bind')]"/>

    <xsl:template match="xf:instance[@id='fr-form-resources']//DARES-ACEMO-QG-22-1/label">
        <xsl:copy>
            <xsl:value-of select="replace(.,'complex-grid','simple-grid')"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="xf:instance[@id='fr-form-resources']//*[(name()='DARES-ACEMO-QG-22-1' or name()='DARES-ACEMO-QG-23' or name()='DARES-ACEMO-QG-81-1') and not(*)]"/>
    
    <xsl:template match="xhtml:body//xf:output[@id='DARES-ACEMO-QG-22-1-control' or @id='DARES-ACEMO-QG-23-control' or @id='DARES-ACEMO-QG-81-1-control']/@class">
        <xsl:attribute name="{name()}">
            <xsl:value-of select="replace(.,'complex-grid','simple-grid')"/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="xhtml:body//xhtml:table[@name='DARES-ACEMO-QG-22-1' or @name='DARES-ACEMO-QG-23' or @name='DARES-ACEMO-QG-81-1']/@class">
        <xsl:attribute name="{name()}">
            <xsl:value-of select="replace(.,'complex-grid','simple-grid')"/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="xhtml:body//xf:repeat">
        <xsl:apply-templates select="node()"/>
    </xsl:template>

    <xsl:template match="xhtml:body//xf:trigger[@id='DARES-ACEMO-QG-22-1-addline']"/>
    
    <xsl:template match="xf:action/@if | xf:action/xf:setvalue/@*">
        <xsl:attribute name="{name()}">
            <xsl:value-of select="replace(replace(.,
                '//\*\[name\(\)=''DARES-ACEMO-QG-81-1'' and position\(\)= \$DARES-ACEMO-QG-81-1-position \]',''),
                '//\*\[name\(\)=''DARES-ACEMO-QG-81-1'' and count\(preceding-sibling::\*\)=count\(current\(\)/ancestor::\*\[name\(\)=''DARES-ACEMO-QG-81-1''\]/preceding-sibling::\*\)\]','')"/>
<!--            <xsl:value-of select="replace(replace(replace(.,'//*[name()=''DARES-ACEMO-QG-22-1'' and count(preceding-sibling::*)=count(current()/ancestor::*[name()=''DARES-ACEMO-QG-22-1'']/preceding-sibling::*)]','')
                ,'//*[name()=''DARES-ACEMO-QG-23'' and count(preceding-sibling::*)=count(current()/ancestor::*[name()=''DARES-ACEMO-QG-23'']/preceding-sibling::*)]','')
                ,'//*[name()=''DARES-ACEMO-QG-81-1'' and count(preceding-sibling::*)=count(current()/ancestor::*[name()=''DARES-ACEMO-QG-81-1'']/preceding-sibling::*)]','')"/>-->   
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="xf:var[ends-with(@name,'position')]"/>

    <xsl:template match="xf:action[@ev:event='xforms-ready']/xf:action"/>
</xsl:transform>
