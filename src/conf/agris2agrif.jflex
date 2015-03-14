package gr.agroknow.metadata.transformer.agris2agrif;

import gr.agroknow.metadata.agrif.Agrif;
import gr.agroknow.metadata.agrif.Citation;
import gr.agroknow.metadata.agrif.ControlledBlock;
import gr.agroknow.metadata.agrif.Creator;
import gr.agroknow.metadata.agrif.Expression;
import gr.agroknow.metadata.agrif.Item;
import gr.agroknow.metadata.agrif.LanguageBlock;
import gr.agroknow.metadata.agrif.Manifestation;
import gr.agroknow.metadata.agrif.Relation;
import gr.agroknow.metadata.agrif.Rights;

import gr.agroknow.metadata.transformer.ParamManager;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.List;
import java.util.ArrayList;

import net.zettadata.generator.tools.Toolbox;
import net.zettadata.generator.tools.ToolboxException;

%%
%class AGRIS2AGRIF
%standalone
%unicode

%{
	// AGRIF
	private List<Agrif> agrifs ;
	private Agrif agrif ;
	private Citation citation ;
	private ControlledBlock cblock ;
	private Creator creator ;
	private Expression expression ;
	private Item item ;
	private LanguageBlock lblock ;
	private Manifestation manifestation ;
	private Relation relation ;
	private Rights rights ;
	
	// TMP
	private StringBuilder tmp ;
	private String language ;
	private String thesaurus ;
	private String classification ;
	private Item tmpItem ;
	private Manifestation tmpManifestation ;
	
	// EXERNAL
	private String potentialLanguages ;
	private String mtdLanguage ;
	private String providerId ;
	private String manifestationType = "landingPage" ;
	
	public void setPotentialLanguages( String potentialLanguages )
	{
		this.potentialLanguages = potentialLanguages ;
	}
	
	public void setMtdLanguage( String mtdLanguage )
	{
		this.mtdLanguage = mtdLanguage ;
	}
	
	public void setManifestationType( String manifestationType )
	{
		this.manifestationType = manifestationType ;
	}
	
	public void setProviderId( String providerId )
	{
		this.providerId = providerId ;
	}
	
	public List<Agrif> getAgrifs()
	{
		return agrifs ;
	}
	
	private void init()
	{
		agrif = new Agrif() ;
		agrif.setSet( providerId ) ;
		citation  = new Citation() ;
		cblock = new ControlledBlock() ;
		expression = new Expression() ;
		item = new Item() ;
		lblock = new LanguageBlock() ;
		manifestation = new Manifestation() ;
		relation = new Relation() ;
		rights = new Rights() ;
	}
	
	private String utcNow() 
	{
		Calendar cal = Calendar.getInstance();
		SimpleDateFormat sdf = new SimpleDateFormat( "yyyy-MM-dd" );
		return sdf.format(cal.getTime());
	}
	
	private String extract( String element )
	{	
		return element.substring(element.indexOf(">") + 1 , element.indexOf("</") );
	}
	
%}

%state RESOURCES
%state ARN
%state AGRIF
%state LTITLE
%state TITLE
%state CREATOR
%state PUBLISHER
%state DATE
%state SUBJECT
%state THESAURUS
%state DESCRIPTOR
%state CLASSIFICATION
%state CLASS
%state DESCRIPTION
%state ABSTRACT
%state LABSTRACT
%state DESCRIPTIONNOTE
%state LNOTE
%state AVAILABILITY
%state AVAILOCATION
%state FORMAT
%state CITATION
%state COVERAGE
%state URL
%state LKEYWORD
%state KEYWORD
%state LCITATIONTITLE

%%

<YYINITIAL>
{
	"<ags:resources"
	{
		yybegin( RESOURCES ) ;
		agrifs = new ArrayList<Agrif>() ;
	}
	
	"<ags:resource".+"ags:ARN=\"\"" 
	{
		agrifs = new ArrayList<Agrif>() ;
		init() ;
		agrif.setOrigin( providerId, "" ) ;
		yybegin( AGRIF ) ;
	}
	
	"<ags:resource".+"ags:ARN=\""
	{
		agrifs = new ArrayList<Agrif>() ;
		init() ;
		yybegin( ARN ) ;
		tmp = new StringBuilder() ; 
	}
       

}

<RESOURCES>
{
	"</ags:resources>"
	{
		yybegin( YYINITIAL ) ;
	}
	
	"<ags:resource ags:ARN=\""
	{
		init() ;
		yybegin( ARN ) ;
		tmp = new StringBuilder() ; 
	}

        /* 12.1.2014 In case there is nor ARN
        "<ags:resource"
	{
		init() ;
		yybegin( AGRIF ) ;
		
	}
*/
}

<ARN>
{
	"\">"
	{
		agrif.setOrigin( providerId, tmp.toString() ) ;
		yybegin( AGRIF ) ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<AGRIF>
{
	"</ags:resource>"
	{
		if ( !manifestation.toJSONObject().isEmpty() )
		{
			expression.setManifestation( manifestation ) ;
		}
		agrif.setExpression( expression ) ;
		agrif.setLanguageBlocks( lblock ) ;
		agrif.setControlled( cblock ) ;
		agrifs.add( agrif ) ;
		yybegin( RESOURCES ) ;
	}
	
	"<dc:title".+"xml:lang=\""
	{
		yybegin( LTITLE ) ;
		tmp = new StringBuilder() ;
	}
	
	"<dc:title".+"/>" {}
	
	"<dc:title>".+"</dc:title>"
	{
		String text = extract( yytext() ) ;
		lblock.setTitle( ParamManager.getInstance().getLanguageFor(text), text ) ;
	}
	
	
	"<dc:creator>"|"<dc:creator xmlns:dc=\"http://purl.org/dc/elements/1.1/\">"
	{
		yybegin( CREATOR ) ;
	}
	
	"<dc:publisher>"|"<dc:publisher xmlns:dc=\"http://purl.org/dc/elements/1.1/\">"
	{
		yybegin( PUBLISHER ) ;
	}
	
	"<dc:date>"|"<dc:date xmlns:dc=\"http://purl.org/dc/elements/1.1/\">"
	{
		yybegin( DATE ) ;
	}
	
	"<dc:subject>"|"<dc:subject xmlns:dc=\"http://purl.org/dc/elements/1.1/\">"|"<dc:subject xml:lang=\"en\">"
	{
		yybegin( SUBJECT ) ;
		tmp = new StringBuilder() ;	
	}
	
	"<dc:description>"|"<dc:description xmlns:dc="http://purl.org/dc/elements/1.1/">"
	{
		yybegin( DESCRIPTION ) ;
	}

	"<dc:identifier scheme=\"dcterms:URI\">"
	{
		tmp = new StringBuilder() ;
		yybegin( URL ) ;
	}
		
	"<dc:language scheme=\"ags:ISO639-1\">".+"</dc:language>"
	{
		expression.setLanguage( extract( yytext() ) ) ;
	}
	
	"<dc:language scheme=\"ISO639-2\">".+"</dc:language>"
	{
		String tmpLanguage = extract( yytext() ) ;
		try
		{
			tmpLanguage = Toolbox.getInstance().toISO6391( tmpLanguage ) ;
		}
		catch( ToolboxException te ){}
		expression.setLanguage( tmpLanguage ) ;	
	}
	
	"<dc:language".+"scheme=\"dcterms:ISO639-2\">".+"</dc:language>"
	{
		String tmpLanguage = extract( yytext() ) ;
		try
		{
			tmpLanguage = Toolbox.getInstance().toISO6391( tmpLanguage ) ;
		}
		catch( ToolboxException te ){}
		expression.setLanguage( tmpLanguage ) ;	
	}
	
	"<agls:availability>"|"<ags:availability>"|"<agls:availability xmlns:agls=\"http://www.naa.gov.au/recordkeeping/gov_online/agls/1.2\">"
	{
		yybegin( AVAILABILITY ) ;
		tmpItem = new Item() ;
		tmpManifestation = new Manifestation() ;
	}
	
	"<dc:type>".+"</dc:type>"
	{
		cblock.setType( "dc:type", extract( yytext() ) ) ;
	}

	"<dc:format>"|"<dc:format xmlns:dc=\"http://purl.org/dc/elements/1.1/\">"
	{
		yybegin( FORMAT ) ;
	}
	
	"<ags:citation>"
	{
		yybegin( CITATION ) ;
		citation = new Citation() ;
	}
		
	
	"<dc:coverage>"
	{
		yybegin( COVERAGE ) ;
	}
 
}

<URL>
{

	"</dc:identifier>"
	{
		item.setDigitalItem( tmp.toString() ) ;
		manifestation.setItem( item ) ;
		manifestation.setManifestationType( manifestationType ) ;
		yybegin( AGRIF ) ;
	}

	"&lt;![CDATA[" {}
	
	"<![CDATA[" {}
	
	"]]&gt;" {}
	
	"]]>" {}
	
	.
	{
		tmp.append( yytext() ) ;
	}

}

<COVERAGE>
{
	"</dc:coverage>"
	{
		yybegin( AGRIF ) ;
	}
    
    "<dcterms:spatial>".+"</dcterms:spatial>"
    {
    	cblock.setSpatialCoverage( "dc:spatial", extract( yytext() ) ) ;
    }

}

<CITATION>
{
	"</ags:citation>"
	{
		yybegin( AGRIF ) ;
		expression.setCitation( citation ) ;
	}
	
	"<ags:citationTitle>".+"</ags:citationTitle>"
	{
		citation.setTitle( extract( yytext() ) ) ;
	}
		
	"<ags:citationTitle xml:lang=\"en\">".+"</ags:citationTitle>"
	{
		citation.setTitle( extract( yytext() ) ) ;
	}
	
	"<ags:citationTitle xml:lang=\"cn\">".+"</ags:citationTitle>"
	{
		citation.setTitle( extract( yytext() ) ) ;
	}
	
	"<ags:citationTitle xml:lang=\"cn\">".+"</ags:citationTitle>"
	{
		citation.setTitle( extract( yytext() ) ) ;
	}
		
	
	"<ags:citationIdentifier scheme=\"ags:ISSN\">".+"</ags:citationIdentifier>"
	{
		citation.setIdentifier( "ISSN", extract( yytext() ) ) ;
	}

	"<ags:citationChronology>".+"</ags:citationChronology>"
	{
		citation.setCitationChronology( extract( yytext() ) ) ;
	}
    
        "<ags:citationNumber>".+"</ags:citationNumber>"
       {
                citation.setCitationNumber( extract( yytext() ) ) ;
        }
	
}

<FORMAT>
{
	"</dc:format>"
	{
		yybegin( AGRIF ) ;
	}
	
	"<dc:extent>".+"</dc:extent>"
	{
		manifestation.setSize( extract( yytext() ) ) ;
	}
	
	"<dcterms:extent>".+"</dcterms:extent>"
	{
		manifestation.setSize( extract( yytext() ) ) ;
	}
	
	"<dcterms:medium>".+"</dcterms:medium>"
	{
		manifestation.setFormat( extract( yytext() ) ) ;
	}
	
	"<dc:medium>".+"</dc:medium>"
	{
		manifestation.setFormat( extract( yytext() ) ) ;
	}
    
}

<AVAILABILITY>
{
	"</agls:availability>"|"</ags:availability>"
	{
		yybegin( AGRIF ) ;
		tmpManifestation.setItem( tmpItem ) ;
		tmpManifestation.setManifestationType( "physicalLocation" ) ;
		expression.setManifestation( tmpManifestation ) ; 
	}
	
	"<ags:availabilityLocation>"
	{
		tmp = new StringBuilder() ;
		yybegin( AVAILOCATION ) ;
	}
	
	
	"<ags:availabilityNumber>".+"</ags:availabilityNumber>"
	{
		tmpItem.setPhysicalNumber( extract( yytext() ) ) ;
	}
    
}


<AVAILOCATION>
{
	"</ags:availabilityLocation>"
	{
		tmpItem.setPhysicalLocation( tmp.toString() ) ;
		yybegin( AVAILABILITY ) ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
	
	\n+
	{
		tmp.append( " " ) ;
	}
}

<DESCRIPTION>
{
	"</dc:description>"
	{
		yybegin( AGRIF ) ;
	}
	
	"<dcterms:abstract>"
	{
		language = null ;
		tmp = new StringBuilder() ;
		yybegin( ABSTRACT ) ;
	}
	
	"<dcterms:abstract xml:lang=\""
	{
		tmp = new StringBuilder() ;
		yybegin( LABSTRACT ) ;
	}
	
	"<ags:descriptionNotes>"
	{
		language = null ;
		tmp = new StringBuilder() ;
		yybegin( DESCRIPTIONNOTE ) ;
	}
	
	"<ags:descriptionNotes xml:lang=\""
	{
		tmp = new StringBuilder() ;
		yybegin( LNOTE ) ;
	}
	
}

<LNOTE>
{
	"\">"
	{
		language = tmp.toString() ;
		if ( language.length() == 3 )
		{
			try
			{
				language = Toolbox.getInstance().toISO6391( language ) ;
			}
			catch( ToolboxException te )
			{
			}
		}
		tmp = new StringBuilder() ;
		yybegin( DESCRIPTIONNOTE ) ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}


<DESCRIPTIONNOTE>
{
	"</ags:descriptionNotes>"
	{
		yybegin( DESCRIPTION ) ;
		String text = tmp.toString() ;
		lblock.setNotes( ParamManager.getInstance().getLanguageFor(text), text ) ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<LABSTRACT>
{
	"\">"
	{
		language = tmp.toString() ;
		if ( language.length() == 3 )
		{
			try
			{
				language = Toolbox.getInstance().toISO6391( language ) ;
			}
			catch( ToolboxException te )
			{
			}
		}
		tmp = new StringBuilder() ;
		yybegin( ABSTRACT ) ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<ABSTRACT>
{
	"</dcterms:abstract>"
	{
		yybegin( DESCRIPTION ) ;
		String text = tmp.toString() ;
		lblock.setAbstract( ParamManager.getInstance().getLanguageFor(text), text ) ;
	}
	
	//"&lt;![CDATA[" {}
	
	//"<![CDATA[" {}
	
	//"]]&gt;" {}
	
	//"]]>" {}	
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<SUBJECT>
{
	"</dc:subject>"
	{
		yybegin( AGRIF ) ;
		if (tmp != null )
		{
			String text = tmp.toString().trim() ;
			if ( !text.isEmpty() )
			{
				lblock.setKeyword( ParamManager.getInstance().getLanguageFor(text), text ) ;
			}
		}
	}
	
	"<ags:subjectThesaurus xml:lang=\""
	{
		yybegin( LKEYWORD ) ;
		tmp = new StringBuilder() ;
	}

    "<ags:subjectClassification xml:lang=\""
    {
    	yybegin( LKEYWORD ) ;
		tmp = new StringBuilder() ;
    }

    "<dc:subject xml:lang=\""
    {
    	yybegin( LKEYWORD ) ;
		tmp = new StringBuilder() ;
    }
	
	
    "<ags:subjectClassification"	 
    {
    	yybegin( LKEYWORD ) ;
		tmp = new StringBuilder() ;
		tmp.append( "en" ) ;
    }
	
	"<ags:subjectClassification".+"scheme=\"dcterms:"
	{
		tmp = new StringBuilder() ;
		yybegin( CLASSIFICATION ) ;
	}

	"<ags:subjectClassification".+"scheme=\"ags:"
	{
		tmp = new StringBuilder() ;
		yybegin( CLASSIFICATION ) ;
	}
	
	
	"<ags:subjectThesaurus".+"scheme=\"ags:"
	{
		tmp = new StringBuilder() ;
		yybegin( THESAURUS ) ;
	}
		
	
	.
	{
		if (tmp != null )
		{
			tmp.append( yytext() ) ;
		}
	}
	
}

<LKEYWORD>
{
	"\">"|">"
	{
		language = tmp.toString() ;
		if ( language.length() == 3 )
		{
			try
			{
				language = Toolbox.getInstance().toISO6391( language ) ;
			}
			catch( ToolboxException te )
			{
			}
		}
		yybegin( KEYWORD ) ;
		tmp = new StringBuilder() ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<KEYWORD>
{
	"</ags:subjectThesaurus>"|"</ags:subjectClassification>"|"</dc:subject>"
	{
		lblock.setKeyword( language, tmp.toString() ) ;
		yybegin( SUBJECT ) ;	
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<CLASSIFICATION>
{
	"\">"
	{
		classification = tmp.toString() ;
		tmp = new StringBuilder() ;
		yybegin( CLASS ) ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
	
}

<THESAURUS>
{
	
	"\"".+"\">"|"\">"
	{
		thesaurus = tmp.toString() ;
		tmp = new StringBuilder() ;
		yybegin( DESCRIPTOR ) ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<CLASS>
{
	"</ags:subjectClassification>"
	{
		cblock.setDescriptor( classification, tmp.toString() ) ;
		yybegin( SUBJECT ) ;
		tmp = null ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<DESCRIPTOR>
{
	"</ags:subjectThesaurus>"
	{
		cblock.setDescriptor( thesaurus, tmp.toString() ) ;
		yybegin( SUBJECT ) ;
		tmp = null ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<DATE>
{
	"</dc:date>"
	{
		yybegin( AGRIF ) ;
	}

	"<dcterms:dateIssued>".+"</dcterms:dateIssued>"|"<dcterms:dateIssued scheme=\"dcterms:W3CDTF\">".+"</dcterms:dateIssued>"
	{
		expression.setDateIssued( extract( yytext() ) ) ;
		// System.out.println( extract( yytext() ) ) ;
	}       

}

<PUBLISHER>
{
	"</dc:publisher>"
	{
		yybegin( AGRIF ) ;
	}
	
	"<ags:publisherName>".+"</ags:publisherName>"
	{
		expression.setPublisher( extract( yytext() ), null, null ) ;
	}

         "<ags:publisherDate>".+"</ags:publisherDate>"
	{
		expression.setPublisher( null,  extract( yytext() ), null ) ;
	}


        "<ags:publisherPlace>".+"</ags:publisherPlace>"
	{
		expression.setPublisher( null, null, extract( yytext() ) ) ;
	}

}

<CREATOR>
{
	"</dc:creator>"
	{
		yybegin( AGRIF ) ;
	}
	
	"<ags:creatorPersonal>".+"</ags:creatorPersonal>"
	{
		creator = new Creator( "person", extract( yytext() ) ) ;
		agrif.setCreator( creator ) ;
	}
	
	"<ags:creatorConference>".+"</ags:creatorConference>"
	{
		creator = new Creator( "conference", extract( yytext() ) ) ;
		agrif.setCreator( creator ) ;
	}
	
	"<ags:creatorCorporate>".+"</ags:creatorCorporate>"
	{
		creator = new Creator( "organization", extract( yytext() ) ) ;
		agrif.setCreator( creator ) ;
	}		
}

<LCITATIONTITLE>
{

	"\">"
	{
		citation.setTitle( extract( yytext() ) ) ;
	}
	yybegin( CITATION ) ;
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<LTITLE>
{	
	"\">"
	{
		language = tmp.toString() ;
		if ( language.length() == 3 )
		{
			try
			{
				language = Toolbox.getInstance().toISO6391( language ) ;
			}
			catch( ToolboxException te )
			{
			}
		}
		yybegin( TITLE ) ;
		tmp = new StringBuilder() ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<TITLE>
{
	"</dc:title>"
	{
		lblock.setTitle( language, tmp.toString() ) ;
		yybegin( AGRIF ) ;
	}
	
	"<![CDATA[" {}
	
	"]]>" {}
	
	.
	{
		tmp.append( yytext() ) ;
	}
	
}
	
/* error fallback */
.|\n 
{
	//throw new Error("Illegal character <"+ yytext()+">") ;
}