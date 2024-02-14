/// <pre>
/// Copyright (c) Alex Woodhead 2022
/// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
/// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
/// License MIT
/// Source: https://github.com/alexatwoodhead/SendComplexMessageFromService
/// Version: 1.0
/// </pre>
/// Utility to send complex nested persistent types supporting XML Adapter from IRIS Integration<br/>
/// Common workflow:<ol>
/// <li>Select Sending service from List</li>
/// <li>Select Target Business Process or Operation from List</li>
/// <li>Select Message Class (Persistent class implementing XMLAdapter from List)</li>
/// </ol>
/// Continued Workflow 1:<ul>
/// <li>Paste existing XML message representation into textarea</li>
/// <li>Press "Submit Query" button</li>
/// </ul>
/// Continued Workflow 2:<ul>
/// <li>Specify the numeric ID / ROWID of an existing message record. Hint as seen in property MessageBodyId in MessageHeader
/// <li>Press "Submit Query" button</li>
/// <li>Optional adjust the XML content</li>
/// <li>Press "Submit Query" button</li>
/// </ul>
/// Indents the XML for easier viewing<br/>
/// Once message has been sent in production a link is displayed at the top of the page. Open link to see message trace.<br/>
/// Note: If the production is not running the status is visible next to production name and the submit button is disabled.
Class alwo.integ.SendComplexMessageFromService Extends %CSP.Page
{

ClassMethod OnPage() As %Status
{
#dim %response as %CSP.Response
	
	set action=$G(%request.Data("Action",1),"drawForm")
	set pService=$G(%request.Data("Service",1))
	set pTarget=$G(%request.Data("Target",1))
	set pCorrelateClass=$G(%request.Data("CorrelateClass",1))
	set pCorrelateId=+$G(%request.Data("CorrelateId",1))
	set iCorrelatePart=0
	set pCorrelateData=""
	for {
		set iCorrelatePart=$O(%request.Data("CorrelateData",iCorrelatePart))
		quit:iCorrelatePart=""
		set pCorrelateData=pCorrelateData_$G(%request.Data("CorrelateData",iCorrelatePart))
	}
	
	s xmlOriginal=pCorrelateData
	s pCorrelateData=$TR(pCorrelateData,$C(10,13))
	
	&html<<html>
<head>
</head>
<body>>
	
	try {
		

		if pService'="",pTarget'="",pCorrelateClass'="",pCorrelateData'="" {
			do {
				
				set rootTag=$P($ZSTRIP($P(pCorrelateData,">"),"<>W"),"<",2)
				if rootTag="" {
					&HTML<<p>Root Element not found for TestMessage</p>>
					quit	
				}
				set:pCorrelateData'["http://www.w3.org/2001/XMLSchema" $P(pCorrelateData,"<"_rootTag,2)=$P(pCorrelateData,"<"_rootTag,1)_" xmlns:xsi=""http://www.w3.org/2001/XMLSchema"""_$P(pCorrelateData,"<"_rootTag,2)
				
				//w !,"<pre>",pCorrelateData,"</pre>"
				
				Set reader = ##class(%XML.Reader).%New()
				Set tSC=reader.OpenString(pCorrelateData)
				if $SYSTEM.Status.IsError(tSC) {
					&HTML<<p>Error OpenString.</p>>
					W !,$SYSTEM.Status.GetOneErrorText(tSC)
					quit
				}
				Do reader.Correlate(rootTag,pCorrelateClass)
				if 'reader.Next(.pRequest,.tSC) {
					&HTML<<p>Unable to correlate class #(pCorrelateClass)# with supplied message.</p>>
					W !,$SYSTEM.Status.GetOneErrorText(tSC)
					quit // do	
				}
				if $SYSTEM.Status.IsError(tSC) {
					&HTML<<p>Error correlating message.</p>>
					W !,$SYSTEM.Status.GetOneErrorText(tSC)
					quit
				}
				
				// TODO Check if production is running				
				#dim svc as Ens.BusinessService
				set tSC=##class(Ens.Director).CreateBusinessService(pService,.svc)
				if $SYSTEM.Status.IsError(tSC) {
					&HTML<<p>Error creating Business Service.</p>>
					W !,$SYSTEM.Status.GetOneErrorText(tSC)
					quit	
				}
				set tSC=svc.SendRequestAsync(pTarget,pRequest,"TESTING")
				if $SYSTEM.Status.IsError(tSC) {
					&HTML<<p>Error sending request.</p>>
					W !,$SYSTEM.Status.GetOneErrorText(tSC)
					quit
				}
				set session=svc.%SessionId
				&html<<p>Message sent in session <a href="EnsPortal.VisualTrace.zen?SESSIONID=#(session)#" target="_blank">#(session)#</a></p><hr/>>
				do ..DrawForm(.pService,.pTarget,.pCorrelateClass,.xmlOriginal)
			} while 0
			
		} elseif pCorrelateId>0,pCorrelateData="",pCorrelateClass'="",$CLASSMETHOD(pCorrelateClass,"%ExistsId",pCorrelateId) {
			/// Load XML representation of Data to form for optional Edit
			set obj=$CLASSMETHOD(pCorrelateClass,"%OpenId",pCorrelateId,0)
			do obj.XMLExportToString(.xmlOriginal,,",ignorenull,indent( )")
			do ..DrawForm(.pService,.pTarget,.pCorrelateClass,.xmlOriginal)
		} else {
			/// First display
			do ..DrawForm(.pService,.pTarget,pCorrelateClass,.xmlOriginal)
		}
		#dim err as %Exception.AbstractException
	} catch err {
		W !,"<p>",err.DisplayString(),"</p>"
		set %response.TraceDump=1
	}
	&html<</body>
</html>>

	Quit $$$OK
}

ClassMethod DrawForm(pService = "", pTarget = "", pCorrelateClass = "", pCorrelateData = "")
{
	// TODO Check if production is running
	
	set rs=##class(%ResultSet).%New("%Library.ClassDefinition:SubclassOf")
	set tSC=rs.Execute("Ens.BusinessService")
	for {
		quit:'rs.Next()
		set data=rs.Get("Name")
		continue:data=""
		set hosts(data)=""	
	}
	
	set rs=##class(%ResultSet).%New("%Library.ClassDefinition:SubclassOf")
	set tSC=rs.Execute("%Library.Persistent")
	for {
		quit:'rs.Next()
		set data=rs.Get("Name")
		continue:data=""
		continue:$E(data,1)="%"
		continue:$P(data,".")="EnsLib"
		continue:$P(data,".")="Ens"
		continue:$P(data,".")="EnsPortal"
		continue:$P(data,".")="CSPX"
		continue:$P(data,".")="INFORMATION"
		set persistent(data)=""
	}
	
	set rs=##class(%ResultSet).%New("%Library.ClassDefinition:SubclassOf")
	set tSC=rs.Execute("%XML.Adaptor")
	for {
		quit:'rs.Next()
		set data=rs.Get("Name")
		continue:data=""
		continue:'$Data(persistent(data)) // filter out non-persistent types
		continue:$E(data,1)="%"
		continue:$P(data,".")="EnsLib"
		continue:$P(data,".")="Ens"
		continue:$P(data,".")="EnsPortal"
		continue:$P(data,".")="CSPX"
		continue:$P(data,".")="INFORMATION"
		set xmls(data)=""
	}
	
	// Get Current production
	d ##class(Ens.Director).GetProductionStatus(.pProductionName,.state)
	
	W !,"<h3>Namespace: ",$NAMESPACE,"</h3>"
	W !,"<h3>Production name: ",pProductionName," (",$S(state<0:Backup,state=1:"Running",state=2:"Stopped",state=3:"Suspended",state=4:"Troubled",state=5:"NetworkStopped",1:Unknown),")</h3>"
	
	&SQL(DECLARE ProductionItems CURSOR FOR
		Select top 100 Name,Classname
		into :pName,:pClassName
		from Ens_Config.Item
		where Production=:pProductionName)
	&SQL(OPEN ProductionItems)
	for {
		&SQL(FETCH ProductionItems)
		Quit:SQLCODE'=0
		continue:pName=""
		if pClassName'="" {
			if $Data(hosts(pClassName)) {
				set selectServices(pName)=""
			} else {
				set listProcessOperations(pName)=""
			}
		}
	}
	&SQL(CLOSE ProductionItems)
	
	
	&html<<form action="alwo.integ.SendComplexMessageFromService.cls" method="POST">>
	&html<<table>>
	// Get a list of services for current production
	&html<<tr><td><label>Sending Service</label></td>>
	&html<<td><Select name="Service"><Option value="">[Select]</Option>>
	set iHost=""
	for {
		set iHost=$Order(selectServices(iHost))
		quit:iHost=""
		W !,"<Option value="""
		W ..EscapeHTML(iHost),""" "
		W $Select(iHost=pService:" Selected",1:"")
		W ">",..EscapeHTML(iHost),"</option>"
	}
	&html<</Select></td></tr>>
	

	&html<<tr><td><label>Target</label></td><td><Select name="Target"><Option value="">[Select]</Option>>
	set iHost=""
	for {
		set iHost=$Order(listProcessOperations(iHost))
		quit:iHost=""
		W !,"<Option value="""
		W ..EscapeHTML(iHost),""" "
		W $Select(iHost=pTarget:" Selected",1:"")
		W ">",..EscapeHTML(iHost),"</option>"
	}
	&html<</Select></td></tr>>
	
	
	&html<<tr><td><label>Classname to correlate</label></td><td><Select name="CorrelateClass"><Option value="">[Select]</Option>>
	set iXML=""
	for {
		set iXML=$Order(xmls(iXML))
		quit:iXML=""
		W !,"<Option value="""
		W ..EscapeHTML(iXML),""" "
		W $Select(iXML=pCorrelateClass:" Selected",1:"")
		W ">",..EscapeHTML(iXML),"</option>"
	}
	&html<</Select></td></tr>>
	
	&html<<tr><td><label>Populate XML from MessageBodyId</label></td><td><input type="text" name="CorrelateId"></input></td></tr>>
	
	
	&html<<tr><td><label>Message XML</label></td><td><textarea cols=120 rows=20 name="CorrelateData">#(pCorrelateData)#</textarea></td></tr>>
	
	&html<<tr><td><input type="submit" #($S(state=1:"",1:" disabled=1"))#/></td><td></td></tr>>
	&html<</table></form><hr/>>
}

}

