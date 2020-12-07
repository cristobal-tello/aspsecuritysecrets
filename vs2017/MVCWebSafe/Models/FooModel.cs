using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace MVCWebSafe.Models
{
    public class FooModel
    {
        [AllowHtml]
        public string FooProperty { get; set; }
    }
}