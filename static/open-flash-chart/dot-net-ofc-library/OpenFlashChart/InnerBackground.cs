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

namespace OpenFlashChart
{
    #region Header
    /// <summary>
    /// Represents the inner background object.
    /// </summary>
    #endregion
    public class InnerBackground
    {
        #region Private Variables
        string _bg_color_end;
        string _bg_color_start;
        int _bg_angle;
        #endregion

        #region Public Properties
        /// <summary>
        /// Gets or sets a hex color string value of the ending color.
        /// </summary>
        public string ColorEnd
        {
            get { return _bg_color_end; }
            set { _bg_color_end = value; }
        }
        /// <summary>
        /// Gets or sets a hex color string value of the starting color.
        /// </summary>
        public string ColorStart
        {
            get { return _bg_color_start; }
            set { _bg_color_start = value; }
        }
        /// <summary>
        /// Gets or sets the angle of the gradient between the start and end.
        /// </summary>
        public int Angle
        {
            get { return _bg_angle; }
            set { _bg_angle = value; }
        }
        #endregion

        #region Constructor
        /// <summary>
        /// Creates an instance of the inner background object.
        /// </summary>
        /// <param name="start">Sets a hex color string value of the starting color.</param>
        /// <param name="end">Sets the angle of the gradient between the start and end.</param>
        /// <param name="angle">Sets the angle of the gradient between the start and end.</param>
        public InnerBackground(string start, string end, int angle)
        {
            this.ColorStart = start;
            this.ColorEnd = end;
            this.Angle = angle;
        }
        /// <summary>
        /// Creates an instance of the inner background object.
        /// </summary>
        /// <param name="start">Sets a hex color string value of the starting color.</param>
        /// <param name="end">Sets the angle of the gradient between the start and end.</param>
        public InnerBackground(string start, string end)
        {
            this.ColorStart = start;
            this.ColorEnd = end;
            this.Angle = -1;
        }
        /// <summary>
        /// Creates an instance of the inner background object.
        /// </summary>
        /// <param name="start">Sets a hex color string value of the starting color.</param>
        public InnerBackground(string start)
        {
            this.ColorStart = start;
            this.ColorEnd = null;
            this.Angle = -1;
        }
        #endregion

        #region Public Methods
        /// <summary>
        /// Converts the InnerBackground object to a string.
        /// </summary>
        /// <returns>Returns a string representing the InnerBackground object.</returns>
        public override string ToString()
        {
            StringBuilder sb = new StringBuilder(string.Format("&inner_background={0}", this.ColorStart));
            if (this.ColorEnd.Length > 0)
                sb.Append(string.Format(",{0},{1}", this.ColorEnd, this.Angle));
            sb.Append("&\r\n");
            return sb.ToString();
        }
        #endregion
    }
}
