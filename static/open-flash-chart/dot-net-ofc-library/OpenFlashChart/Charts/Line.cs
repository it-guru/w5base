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
    /// Represents the Line chart object.
    /// </summary>
    #endregion
    public class Line : ChartData
    {
        #region Private Variables
        int _width;
        int _size;
        string _color;
        string _text;
        int _circles;
        #endregion

        #region Public Properties
        /// <summary>
        /// Gets or sets the line width.
        /// </summary>
        public int Width
        {
            get { return _width; }
            set { _width = value; }
        }
        /// <summary>
        /// Gets or sets the label font size.
        /// </summary>
        public int Size
        {
            get { return _size; }
            set { _size = value; }
        }
        /// <summary>
        /// Gets or sets the color of the line.
        /// </summary>
        public string Color
        {
            get { return _color; }
            set { _color = value; }
        }
        /// <summary>
        /// Gets or sets the label text.
        /// </summary>
        public string Text
        {
            get { return _text; }
            set { _text = value; }
        }
        /// <summary>
        /// Gets or sets the size of circles (points).
        /// </summary>
        public int Circles
        {
            get { return _circles; }
            set { _circles = value; }
        }
        #endregion

        #region Constructor
        /// <summary>
        /// Creates an instance of the Line chart object.
        /// </summary>
        /// <param name="width">A integer representing the width of the line</param>
        /// <param name="color">A string representing the color of the line in hex.</param>
        /// <param name="text">A string representing the legend label.</param>
        /// <param name="size">A integer value of the legend label font size.</param>
        /// <param name="circles">A integer value of the size of circles (points).</param>
        public Line(int width, string color, string text, int size, int circles)
        {
            this.Width = width;
            this.Size = size;
            this.Color = color;
            this.Text = text;
            this.Circles = circles;
        }
        /// <summary>
        /// Creates an instance of the Line chart object.
        /// </summary>
        /// <param name="width">A integer representing the width of the line</param>
        public Line(int width)
        {
            this.Width = width;
            this.Size = -1;
            this.Color = string.Empty;
            this.Text = string.Empty;
            this.Circles = -1;
        }

        #endregion

        #region Public Methods
        /// <summary>
        /// Converts the Line chart object to a string.
        /// </summary>
        /// <returns>Returns the string value of the Line chart object.</returns>
        public override string ToString()
        {
            StringBuilder sb = new StringBuilder("");
            if (this.Width > 0)
                sb.Append(string.Format("{0},{1}", this.Width, this.Color));
            if (this.Text.Length > 0)
                sb.Append(string.Format(",{0},{1}", this.Text, this.Size));
            if (this.Circles > 0)
                sb.Append("," + this.Circles);
            sb.Append("&\r\n");
            return sb.ToString();
        }
        #endregion
    }
}
