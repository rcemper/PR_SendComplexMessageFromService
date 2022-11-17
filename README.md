# SendComplexMessageFromService
IRIS Integration testing helper. Send complex deep objects as XML from Production Services

# Background
When resending messages for Testing for HL7 virtual documents there is ability to "Edit and Resend"<br/>
For resending messages that are persistent objects with XML serialization capability it is possible to edit the "top level" object.<br/>
This tool hopes to add to this by helping send / "Edit and Resend" objects with a deeper object graph.<br/>

# Install options:
 - IPM (ZPM): install alwo-SendComplexMessageFromService
 - Studio users: Import file /src/SendComplexMessageFromService.xml
 - Visual Studio Code: /udl/alwo/integ/SendComplexMessageFromService.CLS
 
# URL to access
If the SMP production view is accessed via:<br/>
http://localhost:52773/csp/healthshare/thenamespace/EnsPortal.ProductionConfig.zen<br/>
Then this tool can be accessed from:<br/>
http://localhost:52773/csp/healthshare/thenamespace/alwo.integ.SendComplexMessageFromService.cls<br/>
Could bookmark in browser for each production namespace.

# Start Page
The web page will show the current production name and status.
Unless production is already running the utility will be disabled.

![StartScreen](/images/StartScreen.png "StartScreen")

# Workflow
Start by adding:
* Service to send message from
* Target to recieve message
* Classname of message (Only classes that are both Persistent and extend XML adapter are listed)

![CommonOptions](/images/CommonOptions.png "CommonOptions")

# Continued Workflow 1
* Paste existing XML message representation into textarea
* Press "Submit Query" button

# Alternative Workflow 2
* Specify the numeric ID / ROWID of an existing message record. Hint as seen in property MessageBodyId in MessageHeader
* Press "Submit Query" button
* Optionally adjust the XML content
* Press "Submit Query" button

![MessageSent](/images/MessageSent.png "MessageSent")

Use the "Message sent in session" link to open message trace
![MessageTrace](/images/MessageTrace.png "MessageTrace")



