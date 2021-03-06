﻿1) Using Visual Studio 2012

- File>New>Project
- Visual C#>Web>ASP.NET Web Forms Site

2) Named: WebSafe2012

3) Setup IIS and host file to use http://websafe2012.com from you local enviroment

4) On web.config we change the connection string database to use our local sql server express instance

connectionString="Server=(local);Database=WebSafe2012;Trusted_Connection=true"

- Make sure you app IIS APPPOOL\DefaultAppPool (or similar) has dbcreator permissions on your Sql Server instance.

If pool doesn't have access, add it like https://stackoverflow.com/questions/7698286/login-failed-for-user-iis-apppool-asp-net-v4-0
Later, on APPPOOL\DefaultAppPool (or similar) user, on properties, Server Roles check dbcreator and public roles.

5) Run the app

6) Using Chrome and Dev.tools, take a look site cookies.

7) Right now there is only one cookie, '__AntiXsrfToken'

8) Register using top right link

9) Once you are log in, check again your cookies. A new cookie has added, .ASPXAUTH

10) Login into Sql Server instance used in the connection string (Step 4) and use WebSafe2012 database (this database is created automatically by app)

11) Run next query into WebSafe2012 database

select * from dbo.Memberships

For now, just take a look the records values

12) Change the Forms Authentication Timeout
Open web.config and look for:

<authentication mode="Forms">
      <forms loginUrl="~/Account/Login.aspx" timeout="2880" />

We need to reduce timeout value (in minutes, by default 2 days) the user is login into our application.
Eg. if user never close the browser, by default, it will be login during 2 days. 

Best practice is reduce the timeout value, shorter value, safest. It will depend of the app. We will change to 2 hours=120.

<forms loginUrl="~/Account/Login.aspx" timeout="120" />

Another attribute that we can change is slidingExpiration (by default is ON). If it's ON every time the user use our app the timeout will be reset. If it is Off (not by default, but usually, safest) the timeout is not reset, so in 120 the user will be log off. Again, we need to adjust this value depeding how app is designed.

<forms loginUrl="~/Account/Login.aspx" timeout="120" name="websafe2012" slidingExpiration="false" />

13) Check .ASPXAUTH cookie
Using google dev tools, make sure HTTP check is enabled (by default)

On web.config:

Look for: 
<forms loginUrl="~/Account/Login.aspx" timeout="120" />

Add 'name' attribute to change the name of the cookie to another name (this way we hide the app is made using asp.net)
Also, when app goes to production, enable requireSSL

<forms loginUrl="~/Account/Login.aspx" timeout="120" name="websafe2012" requireSSL="true" />

14) Membership
Take a look the attributes of '<add>'. Luckly, there are quite safe by default. Of course, you can change password length to be large,etc...

<membership defaultProvider="DefaultMembershipProvider">
<providers>
    <add name="DefaultMembershipProvider" type="System.Web.Providers.DefaultMembershipProvider, System.Web.Providers, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" connectionStringName="DefaultConnection" enablePasswordRetrieval="false" enablePasswordReset="true" requiresQuestionAndAnswer="false" requiresUniqueEmail="false" maxInvalidPasswordAttempts="5" minRequiredPasswordLength="6" minRequiredNonalphanumericCharacters="0" passwordAttemptWindow="10" applicationName="/" />
</providers>

15) Roles
We want to create a page where only an user with admin roles can access

To do this example easiest we also create a page where a login user will be automatically gain admin roles.

15.1) Create an admin page, Add>New Item>Web Form using Master page. Named admin.aspx

15.2) Add some text in the admin.aspx 
<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <h1>This is an admin page</h1>
</asp:Content>

15.3) Create another page to allow current user to be admin. Named: UserToAdmin.aspx

Add next code:

protected void Page_Load(object sender, EventArgs e)
        {
            Roles.CreateRole("Admin");
            Roles.AddUserToRole(User.Identity.Name, "Admin");
        }
15.4) On web.config, look for '<location' tag. If it is not there create it.

<location path="Admin.aspx">
    <system.web>
      <authorization>
        <allow roles="Admin" />
        <deny users="*" />
      </authorization>
    </system.web>
</location>

15.5) Run the app, login if you're not login yet, an open http://www.websafe2012.com/admin.aspx. You will note the app ask for log in again. That's because we don't have Admin role.

15.6) Open http://www.websafe2012.com/UserToAdmin.aspx, but you will get an Role Manager feature has not been enabled error (remember in this example we didn't turn off notification errors)

15.7) We need to enable Role Manager, go to web.config, look <rolemanager tag and set Enabled attributte to True:

<roleManager defaultProvider="DefaultRoleProvider" enabled="true">

15.8) Try again http://www.websafe2012.com/UserToAdmin.aspx and now you don't get any exception and an empty asp.net page will be load sucessfully. Then, try again to go to http://www.websafe2012.com/admin.aspx and now the Admin page will load without any problem.

16) Check Roles table

Open websafe2012 database in Sql Server Managament Studio and run next query:

select * from dbo.Roles
select * from dbo.UsersInRoles
select * from dbo.Memberships

Take a look how records are link.

17) Viewstate
Create this simple DropDown in a default page

<asp:DropDownList runat="server" ID="ProductDropDown" AutoPostBack="True" />

Also, in Page_Load:

if(!Page.IsPostBack)
{
ProductDropDown.DataSource = new [] {"Milk", "Chocolate", "Cookies"};
ProductDropDown.DataBind();
}

Run app and do some clicks over Dropdown, selecting an item.

How list is not clear if code only Dropdown one time? Due ViewState, because is enable by default in DropDown control.
Take a look the Original Source of Default page (Ctrl+U) under Google Chrome. 
You will see <input type="hidden" name="__VIEWSTATE" with as BASE64 string

On Web.config, go to <pages>, add enableViewStateMac="true"
Luckly, is True by default, so __VIEWSTATE will be check  on the server and if it is modified, don't be proceesed.
In very very strange cases set this flag to False. 

17.1) Copy the value of the __VIEWSTATE, go to http://viewstatedecoder.azurewebsites.net/, paste it and take a look if it can decrypt.

17.2) Cross site scripting

Be careful some control don't encode text values:

On.aspx:
<asp:Button runat="server" ID="MyButton" />
<asp:Label runat="server" ID="MyLabel" />

On .cs:
MyButton.Text = "<script>alert('Button alert!!');</script>";
MyLabel.Text = "<script>alert('Label alert!!');</script>";		// Opsss!!!

You need check the documentation of the control to prevent this issue.

17.3) XSRF attacks
Luckly, at least from VS2012 (I don't know if VS2010), when you create a new webforms site from template, XSRF attacks are mitigated.
Take a look code on Site.Master.cs

17.4) XSS on Login
In you try to put some invalid user when you try to register a new user like this:

On User Name, type something like this:
<script>alert('Opsss!!');</script>

On email and password fields type a valid value.

Try to register and you will get HttpRequestValidationException. This is great.

But if you want disallow ValidateRequest, go to Login field, in this case on Register.aspx
on <asp:TextBox runat="server" ID="UserName" />

Add ValidateRequestMode="Disabled"

<asp:TextBox runat="server" ID="UserName" ValidateRequestMode="Disabled" />

And try again, you will note xss now is allow, but the problem is when template render index page again
using the text that you placed in the textbox. So, the REAL problem is on the label. 
Of course, ValidateRequestMode must be Enabled, but be careful with this behaviour.




