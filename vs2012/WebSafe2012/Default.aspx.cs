using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebSafe2012
{
    public partial class _Default : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                ProductDropDown.DataSource = new[] { "Milk", "Chocolate", "Cookies" };
                ProductDropDown.DataBind();
            }

            MyButton.Text = "<script>alert('Button alert!!');</script>";
            MyLabel.Text = "<script>alert('Label alert!!');</script>";
        }
    }
}