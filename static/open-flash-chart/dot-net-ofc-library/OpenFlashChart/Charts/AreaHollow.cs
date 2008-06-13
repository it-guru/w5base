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
using System.Text;
#endregion

namespace OpenFlashChart.Charts
{
    #region Header
    /// <summary>
    /// Represents the area hollow chart object.
    /// </summary>
    #endregion
    public class AreaHollow : ChartData
    {
        #region Private Variables
        int _width;
        int _dot_size;
        string _color;
        int _alpha;
        string _text;
        int _font_size;
        string _fill;
        #endregion

        #region Public Properties
        /// <summary>
        /// Gets or sets the width of the line.
        /// </summary>
        public int Width
        {
            get { return _width; }
            set { _width = value; }
        }
        /// <summary>
        /// Gets or sets the dot size.
        /// </summary>
        public int DotSize
        {
            get { return _dot_size; }
            set { _dot_size = value; }
        }
        /// <summary>
        /// Gets or sets the line color.
        /// </summary>
        public string Color
        {
            get { return _color; }
            set { _color = value; }
        }
        /// <summary>
        /// Gets or sets the percentage of opacity (transparency).
        /// </summary>
        public int Alpha
        {
            get { return _alpha; }
            set { _alpha = value; }
        }
        /// <summary>
        /// Gets or sets the legend label.
        /// </summary>
        public string Text
        {
            get { return _text; }
            set { _text = value; }
        }
        /// <summary>
        /// Gets or sets the font size of the label.
        /// </summary>
        public int FontSize
        {
            get { return _font_size; }
            set { _font_size = value; }
        }
        /// <summary>
        /// Gets or sets the color to fill below the line.
        /// </summary>
        public string FillColor
        {
            get { return _fill; }
            set { _fill = value; }
        }
        #endregion

        #region Constructor
        /// <summary>
        /// Creates an instance of the AreaHollow object.
        /// </summary>
        /// <param name="width">An integer value of the line size.</param>
        /// <param name="dotsize">An integer value of the dot size.</param>
        /// <param name="color">A string representing the color of the line in hex.</param>
        /// <param name="alpha">An integer value of the opacity of the line.</param>
        /// <param name="text">A string representing the legend label.</param>
        /// <param name="fontsize">A integer value of the legend label font size.</param>
        /// <param name="fillcolor">A string representing the color to fill below the line in hex.</param>
        public AreaHollow(int width, int dotsize, string color, int alpha, string text, int fontsize, string fillcolor)
        {
            this.Width = width;
            this.DotSize = dotsize;
            this.Color = color;
            this.Alpha = alpha;
            this.Text = text;
            this.FontSize = fontsize;
            this.FillColor = fillcolor;
        }
        /// <summary>
        /// Creates an instance of the AreaHollow object.
        /// </summary>
        /// <param name="width">An integer value of the line size.</param>
        /// <param name="dotsize">An integer value of the dot size.</param>
        /// <param name="color">A string representing the color of the line in hex.</param>
        /// <param name="alpha">An integer value of the opacity of the line.</param>
        public AreaHollow(int width, int dotsize, string color, int alpha)
        {
            this.Width = width;
            this.DotSize = dotsize;
            this.Color = color;
            this.Alpha = alpha;
            this.Text = string.Empty;
            this.FontSize = 0;
            this.FillColor = string.Empty;
        }

        #endregion

        #region Public Methods
        /// <summary>
        /// Converts the area hollow object to a string.
        /// </summary>
        /// <returns>Returns the string value of the area hollow object.</returns>
        public override string ToString()
        {
            StringBuilder sb = new StringBuilder(string.Format("{0},{1},{2},{3}", this.Width, this.DotSize, this.Alpha, this.Color));
            if (this.Text.Length > 0)
                sb.Append(string.Format(",{0},{1}", this.Text, (this.FontSize == 0) ? string.Empty : this.FontSize.ToString()));
            if (this.FillColor.Length > 0)
                sb.Append("," + this.FillColor);
            sb.Append("&\r\n");
            return sb.ToString();
        }
        #endregion
    }
}
