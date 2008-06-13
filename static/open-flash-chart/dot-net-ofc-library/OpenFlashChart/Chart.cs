#region Copyright (c) Koolwired Solutions, LLC.
/*--------------------------------------------------------------------------
 * Copyright (c) 2007, Koolwired Solutions, LLC.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer. 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution. 
 * Neither the name of Koolwired Solutions, LLC. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission. 
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS
 * AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *--------------------------------------------------------------------------*/
#endregion

#region History
/*--------------------------------------------------------------------------
 * Modification History: 
 * Date       Programmer      Description
 * 09/22/07   Keith Kikta     Inital release.
 *--------------------------------------------------------------------------*/
#endregion

#region References
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
#endregion

namespace OpenFlashChart
{
    #region Header
    /// <summary>
    /// Represents the chart webcontrol object.
    /// </summary>
    #endregion
    [DefaultProperty("Url")]
    [ToolboxData("<{0}:Chart runat=server></{0}:Chart>")]
    public class Chart : WebControl
    {
        #region Public Properties
        /// <summary>
        /// Gets or sets the url of the data file.
        /// </summary>
        [Bindable(true)]
        [Category("Appearance")]
        [DefaultValue("")]
        [Localizable(true)]
        public string Url
        {
            get
            {
                String s = (String)ViewState["Url"];
                return ((s == null) ? String.Empty : s);
            }

            set
            {
                ViewState["Url"] = value;
            }
        }
        /// <summary>
        /// Gets or sets the sequenceId
        /// </summary>
        public int SequenceId
        {
            get
            {
                int i = 0;
                if (Page.Items["SequenceId"] != null)
                    i = (int)Page.Items["SequenceId"];
                return i;
            }
            set { Page.Items["SequenceId"] = value; }
        }
        /// <summary>
        /// Gets or sets a boolean indicating if the SWFObject javascript should be used to load the chart.
        /// </summary>
        [DefaultValue(true)]
        public bool SWFObject {
            get
            {
                bool s = true;
                if(ViewState["SWFObject"] != null)
                    s = (bool)ViewState["SWFObject"];
                return s;
            }
            set
            {
                ViewState["SWFObject"] = value;
            }
        }
        /// <summary>
        /// Gets or sets the height of the chart.
        /// </summary>
        public override Unit Height {
            get {
                return (Unit)ViewState["Height"];
            }
            set {
                ViewState["Height"] = value;
            }
        }
        /// <summary>
        /// Gets or sets the width of the chart.
        /// </summary>
        public override Unit Width {
            get {
                return (Unit)ViewState["Width"];
            }
            set {
                ViewState["Width"] = value;
            }
        }
        #endregion

        #region Protected Methods
        /// <summary>
        /// Renders the chart object to on the page.
        /// </summary>
        /// <param name="output"></param>
        protected override void RenderContents(HtmlTextWriter output)
        {
            if (this.SequenceId == 0)
            {
                output.WriteLine(string.Format("<script type=\"text/javascript\" src=\"{0}/aspnet_client/OpenFlashChart/js/swfobject.js\"></script>", HttpRuntime.AppDomainAppVirtualPath));
            }
            if (this.SWFObject)
            {
                output.WriteLine(string.Format("<div id=\"{0}\" />", this.ClientID));
                output.WriteLine("<script type=\"text/javascript\">");
                output.WriteLine(string.Format("var so = new SWFObject(\"{0}/aspnet_client/OpenFlashChart/open-flash-chart.swf\", \"ofc\", \"{1}\", \"{2}\", \"9\", \"#FFFFFF\");", HttpRuntime.AppDomainAppVirtualPath, this.Width, this.Height));
                output.WriteLine(string.Format("so.addVariable(\"width\", \"{0}\");", this.Width));
                output.WriteLine(string.Format("so.addVariable(\"height\", \"{0}\");", this.Height));
                output.WriteLine(string.Format("so.addVariable(\"data\", \"{0}\");", this.Url));
                output.WriteLine("so.addParam(\"allowScriptAccess\", \"sameDomain\");");
                output.WriteLine(string.Format("so.write(\"{0}\");", this.ClientID));
                output.WriteLine("</script>");
                output.WriteLine("<noscript>");
            }
            output.Write("<object classid=\"clsid:d27cdb6e-ae6d-11cf-96b8-444553540000\" codebase=\"http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0\"");
            output.WriteLine(string.Format("width=\"{0}\" height=\"{1}\" id=\"chart_{2}\" align=\"middle\">", this.Width, this.Height, this.SequenceId));
            output.WriteLine("<param name=\"allowScriptAccess\" value=\"sameDomain\" />");
            output.WriteLine(string.Format("<param name=\"movie\" value=\"{0}/aspnet_client/OpenFlashChart/open-flash-chart.swf?width={1}&height={2}&data={3}\" />", HttpRuntime.AppDomainAppVirtualPath, this.Width, this.Height, this.Url));
            output.WriteLine("<param name=\"quality\" value=\"high\" />");
            output.WriteLine("<param name=\"bgcolor\" value=\"#FFFFFF\" />");
            output.Write(string.Format("<embed src=\"{0}/aspnet_client/OpenFlashChart/open-flash-chart.swf?data={1}\" quality=\"high\" bgcolor=\"#FFFFFF\" width=\"{2}\" height=\"{3}\" name=\"open-flash-chart\" align=\"middle\" allowScriptAccess=\"sameDomain\" ", HttpRuntime.AppDomainAppVirtualPath, this.Url, this.Width, this.Height));
            output.WriteLine(string.Format("type=\"application/x-shockwave-flash\" pluginspage=\"http://www.macromedia.com/go/getflashplayer\" id=\"embed_{0}\" />", this.SequenceId));
            output.WriteLine("</object>");
            if (this.SWFObject)
                output.WriteLine("</noscript>");
            this.SequenceId++;
        }
        #endregion
    }
}
