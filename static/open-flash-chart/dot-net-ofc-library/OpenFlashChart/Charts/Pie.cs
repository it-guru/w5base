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
    /// Represents the Pie chart object.
    /// </summary>
    #endregion
    public class Pie
    {
        #region Public Classes
        #region Header
        /// <summary>
        /// Represents the Pie Piece chart object.
        /// </summary>
        #endregion
        public class Piece
        {
            #region Private Variables
            float _value;
            string _label;
            string _color;
            #endregion

            #region Public Properties
            /// <summary>
            /// Gets or sets the size of the pie piece.
            /// </summary>
            public float Value
            {
                get { return _value; }
                set { _value = value; }
            }
            /// <summary>
            /// Gets or sets the label of the piece.
            /// </summary>
            public string Label
            {
                get { return _label; }
                set { _label = value; }
            }
            /// <summary>
            /// Gets or sets the color of the piece.
            /// </summary>
            public string Color
            {
                get { return _color; }
                set { _color = value; }
            }
            #endregion

            #region Constructor
            /// <summary>
            /// Creates an instance of the pie piece.
            /// </summary>
            /// <param name="value">A integer representing the pie piece size.</param>
            /// <param name="label">A string representing the pie piece label.</param>
            /// <param name="color">A string representing the color of the pie piece in hex.</param>
            public Piece(float value, string label, string color)
            {
                this.Value = value;
                this.Label = label;
                this.Color = color;
            }
            #endregion
        }
        #endregion
            
        #region Private Variables
        List<Piece> _data = new List<Piece>();
        int _alpha;
        string _linecolor;
        string _labelcolor;
        #endregion

        #region Public Properties
        /// <summary>
        /// Gets or sets the piece of the pie.
        /// </summary>
        public List<Piece> Data
        {
            get { return _data; }
            set { _data = value; }
        }
        /// <summary>
        /// Gets or sets the opacity (transparency).
        /// </summary>
        public int Alpha
        {
            get { return _alpha; }
            set { _alpha = value; }
        }
        /// <summary>
        /// Gets or sets the color of the lines.
        /// </summary>
        public string LineColor
        {
            get { return _linecolor; }
            set { _linecolor = value; }
        }
        /// <summary>
        /// Gets or sets the label color.
        /// </summary>
        public string LabelColor
        {
            get { return _labelcolor; }
            set { _labelcolor = value; }
        }
        #endregion

        #region Constructor
        /// <summary>
        /// Creates an instance of the pie chart object.
        /// </summary>
        /// <param name="alpha">A integer representing the opacity of the pie chart.</param>
        /// <param name="linecolor">A string representing the color of the lines in hex.</param>
        /// <param name="labelcolor">A string representing the color of the labels in hex.</param>
        public Pie(int alpha, string linecolor, string labelcolor)
        {
            this.Alpha = alpha;
            this.LineColor = linecolor;
            this.LabelColor = labelcolor;
        }
        #endregion

        #region Public Methods
        /// <summary>
        /// Converts the Pie chart object to a string.
        /// </summary>
        /// <returns>Returns the string value of the Pie chart object.</returns>
        public override string ToString()
        {
            StringBuilder sb = new StringBuilder(string.Format("&pie={0},{1},{2}&\r\n", this.Alpha, this.LineColor, this.LabelColor));
            StringBuilder sbvalue = new StringBuilder("&values=");
            StringBuilder sblabel = new StringBuilder("&pie_labels=");
            StringBuilder sbcolor = new StringBuilder("&colours=");
            for (int i = 0; i < Data.Count; i++)
            {
                if (i != 0)
                {
                    sbvalue.Append(",");
                    sblabel.Append(",");
                    sbcolor.Append(",");
                }
                sbvalue.Append(this.Data[i].Value);
                sblabel.Append(this.Data[i].Label);
                sbcolor.Append(this.Data[i].Color);
            }
            sbvalue.Append("&\r\n");
            sblabel.Append("&\r\n");
            sbcolor.Append("&\r\n");

            return sb.ToString() + sbvalue.ToString() + sblabel.ToString() + sbcolor.ToString();
        }
        #endregion
    }
}
