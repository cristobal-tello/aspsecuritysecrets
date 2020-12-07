1) Setup your local ISS. Make sure ASP.NET is enabled (on IIS options)

2) Setup a new site in your local machine and avoid to use IIS Express 
2.1) Open IIS and create an Add Website
2.2) Site name: MVCWebSafe.com
2.3) Application pool: DefaultAppPool
2.4) Physical path: It's a path where you saved the project
2.5) IP Address: All unassigned
2.6) Port: 80
2.7) Host name: www.MVCWebSafe.com

3) On your host file (usually in C:\WINDOWS\SYSTEMS32\DRIVERS\ETC) add next line:

127.0.0.1	www.mvcwebsafe.com

4) Compile and go to www.mvcwebsafe.com

5) Create an unhandled exception. On Page_Load from About page put a code to generate an exception like this:

// Force an exception
var number = Int32.Parse("text here");

6) Compile and open About page to watch the information that iis shows when an exception occurs.

- Too much information is show to the user. 
- We're leaking a lot of sensitive info. It's good for debugging purposes but NEVER we'll upload the site into production like this.
- The problem it's some default options are not safe. We need to change them.

7) Go to web.config and try to find to '<customErrors>' tag. If it's not there, create it just below <system.web> tag
7.1) First try: <customErrors mode="On" /> and refresh the About page. You will note some sensitive information is gone.
7.2) Try <customErrors mode="Off" /> (it's default!!! it's not safe)
7.3) <customErrors mode="RemoteOnly" /> Best option when you are developing, it shows sensitive information when you work in local

8) Custom Error page
8.1) Try <customErrors mode="On" defaultRedirect="~/Error.aspx" /> on web.config to custom error page. You will need to create Error.aspx page (Webform with masterpage template).
8.2) Add <h1>Error ocurred!!</h1> into Error.aspx page. Build site and go again into About page to watch new custom error page.
8.3) Take a look the url : http://www.mvcwebsafe.com/Error?aspxerrorpath=/About Note ?aspxerrorpath= parameter on url. We need to hide this parameter as well.
8.4) Try <customErrors mode="On" defaultRedirect="~/Error.aspx" redirectMode="ResponseRedirect" />. It is like 8.3 step (it's default)
8.5) Try <customErrors mode="On" defaultRedirect="~/Error.aspx" redirectMode="ResponseRewrite" /> . Note url doesn't change. This way we don't show any information to user in the url

9) Session cookie
9.1)  Add next code into Global.asax.cs. It just create a value into Session (so, it will be store in the cookies automatically by ASP.NET)

void Session_Start(object sender, EventArgs e)
{
    Session["SessionStart"] = DateTime.Now;
}

9.2) On web.config look for <sessionState tag. If it's not there create in <system.web>

<sessionState mode="InProc" customProvider="DefaultSessionProvider" cookieless="UseUri">
<providers>
<add name="DefaultSessionProvider" type="System.Web.Providers.DefaultSessionStateProvider"/>
</providers>
</sessionState>

9.3) Compile and take a look url. The ID is showing the url. This is not a good approach (session hickjacking) but note it can be useful in other scenarios (as shared url, etc..).
9.4) Use a tool to check the cookies of the site (eg. Google Chrome and use dev tools). Take a look the cookie name is ASP.NET_SessionId
9.5) Note when you check the cookies the HtppOnly flag must be enabled/check. Luckly, is enabled by default in ASP.NET
9.6) The name of cookie ASP.NET_SessionId shows to the user (or hacker) the  site is developed using ASP.NET. So, if in the future there is some bug occurs in asp.net, a hacker could you select your site as target only checking the name of the cookies.

To change cookie name, on web.config, use cookieName attribute

<sessionState mode="InProc" customProvider="DefaultSessionProvider" cookieName="MySessionId">

10) Tracing
Useful tracing ONLY when we're debbuging/diagnostics. You can use localOnly="true" to force only log when remote connections comes from local.

10.1) Enable tracing
Inside <system.web> add:

<trace enabled="true"/>

On Default.asax.cx, on Page_Load method add:

Trace.Write("This is a log message");
Trace.Warn("This is a warning message");

Compile and load the site.

10.2) Watch trace log
Add /trace.axd at the end of the url site name, eg:  http://www.mvcwebsafe.com/trace.axd

10.3) Always is better set Enabled flag to false:

<trace enabled="false"/>

10.4) Or use localOnly:
<trace enabled="true" localOnly="true">

11) Securing Content using Location

There is simple and quick way to secure a page

In this example we're to secure Contact page. Only Admin can access this page.

Just below of close tag </system.web> add next:

<location path="Contact">
<system.web>
    <authorization>
		<allow roles="Admin"/>
		<deny users="*"/>
    </authorization>
</system.web>
</location>

12) Hide asp.net version on Response Headers

Using Chrome Dev Tools, reaload Home page and go to Dev tools. On Network menu option, select site name (eg: www.mvcwebsafe.com) and then choose Headers tab.
You will note on Response Headers there is something like this:

X-AspNet-Version: X.Y.ZzZz

We're leaking asp.net version to everybody. If in the future there is an important bug in the used version, an attacker will know in a few seconds our asp.net version.
Better hide the version number. 

On web.config, on <httpRuntime> tag, add next:

<httpRuntime targetFramework="X.Y.Z" enableVersionHeader="false" />

Compile and refresh home page again and take a look if asp.net version is on headers.

13) How cookies are manage

13.1) Add a new cookie 

On Page_Load method, add:

var cookie = new HttpCookie("MyCookie", "abcd");
Response.Cookies.Add(cookie);

Rebuild and use Google Dev Tools or similar and take a look the cookie doesn't have Http check set. This is not good (because cookie could be access by client script)

13.2) Make cookies Http only

Go to web.config and inside <system.web> add:

<httpCookies httpOnlyCookies="true"/>

13.3) Secure the cookie
Right now if we take a look on "Secure" column on Google Dev Tools for a cookie, it will be uncheck. Again, this is not good.

A cookie (with senstive information) will be send only using SSL to avoid Man in The Middle.

To make cookie secure, on web.config, use "requireSSL" attribute:

<httpCookies httpOnlyCookies="true" requireSSL="true"/>

In case https is not available, cookie will not send.

Note: If you're working/testing in your local machine, make sure you have a valid certficate.

14.4) Change it on runtime:

You can set these values on runtime:

var cookie = new HttpCookie("MyCookie", "abcd");
cookie.HttpOnly = true;
cookie.Secure = true;

15) Retail mode
Retail mode is a set that works for all IIS sites (on machine level). With one line we will disable show errors, tracing, and debbuging. 
This change is recommend on production server.

15.1) Enable retail mode

Go to next path (version could change!!) :

<windows folder>\Microsoft.NET\Framework64\v4.0.30319\Config

Open 'machine.config' file. Inside <system.web> add:

<deployment retail="true" />

Don't forget this MACHINE change. All sites in this machine will be affected.

16.1) maxRequestLength

On <system.web> in <httpRuntime> tag

By default, maxRequestLength is set to 4MB

<httpRuntime maxRequestLength="4096" targetFramework="4.5.1" enableVersionHeader="false" />

According to your app, you can increase or decrease this value. Better explanation, http://nullablecode.com/2012/02/maxrequestlength-packet-sizes-size-isnt-everything/

17) Unsafe Header parsing

By default, this value is set to False.
But if you want for any reason allow unsafe headers (not recomended but maybe for an external app). On web.config:

On <system.net> (if not exist, create it)
<system.net>
<settings>
<httpWebRequest useUnsafeHeaderParsing="true" />
</settings>
</system.net>


18) MVC
If you create a new project using MVC template you will get some safe defaults from free:

18.1) If you're create a model like this:
public class FooModel
{
    public string FooProperty { get { return "<script>alert('Opssss');</script>"; } }
}

And you add it in an HomeController:

public ActionResult Index()
{
	return View(new FooModel());
}

In a Home view, usually Index.cshtml

Add <h1>@Model.FooProperty</h1> all you will note XSS is managed.

18.2) Html.Raw

Be careful if you try to use @Html.Raw, in this case, XSS is possible.

<h1>@Html.Raw(@Model.FooProperty)</h1> <!-- Warning: Don't use like this, XSS problem-->

18.3) Http.TextBoxFor and related

Modify FooProperty like this:

public string FooProperty { get;set; }

Add next on Home view just to allow to send some data to controller:

@using (Html.BeginForm())
{
@Html.TextBoxFor(m=>m.FooProperty)
<input type="submit" value="Submit" />
}

Add next code into 

[HttpPost]
public ActionResult Index(FooModel model)
{
return View(model);
}

If you try to set in text box something like this:
<script>alert('hola');</script>

You will get an HttpRequestValidationException 

If you need to allow html for any reason, add next attribute into model field:

[AllowHtml]
public string FooProperty { get; set; }

As you will note, <h1>@Model.FooProperty</h1> protect against XSS but @Html.Raw doesnt.

18.4) Anti Forgery Token  (aka CSRF)

By default, Login template in MVC has protection over CSRF.
Make sure you add these 2 pieces when you working with Authentication/Login.

By default, if you enabled authentication take a look , Login.cshtml you can find

@Html.AntiForgeryToken() in the login form. This line will add a hidden field with one part of the token
The other token is on the cookie. This way we avoid the CSRF attack.

But also you need 2 token pairs are fine in the HttpPost, adding [ValidateAntiForgeryToken] attribute in the controller.

18.5) Authorize attribute
Remeber, you can use [Authorize] attribute in a class or even [Authorize(Roles="Admin")]
You also can combine using [AllowAnonymous] and [RequireHttps]. Usually on Login Methods

eg:

[Authorize(Roles="admin")]
public class Login
{
	[AllowAnonymous]
	[RequireHttps]
	[HttpGet]
	public ActionResult Login(xxxxx)
	{
	...
	}

	[HttpPost]
	[AllowAnonymous]
	[RequireHttps]
	...
	public ActionResult Login(xxxxx)
	{
	...
	}
}

