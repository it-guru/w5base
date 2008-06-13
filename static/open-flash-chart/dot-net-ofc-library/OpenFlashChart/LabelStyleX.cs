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
    /// Represents the X axis label style.
    /// </summary>
    #endregion
    public class LabelStyleX : LabelStyle
    {
        #region Private Variables
        int _orientation;
        int _step;
        string _gridcolor;
        #endregion

        #region Public Properties
        /// <summary>
        /// Gets or sets the label orientation.
        /// </summary>
        public int Orientation
        {
            get { return _orientation; }
            set { _orientation = value; }
        }
        /// <summary>
        /// Gets or sets the label step.
        /// </summary>
        public int Step
        {
            get { return _step; }
            set { _step = value; }
        }
        /// <summary>
        /// Gets or sets the grid color.
        /// </summary>
        public string GridColor
        {
            get { return _gridcolor; }
            set { _gridcolor = value; }
        }
        #endregion

        #region Constructor
        /// <summary>
        /// Creates an instance of the X axis label style object.
        /// </summary>
        /// <param name="size">An integer containing the label size.</param>
        /// <param name="color">A string containing the label color.</param>
        /// <param name="orientation">A integer containing the label orientation.</param>
        /// <param name="step">A integer containing the label step.</param>
        /// <param name="gridcolor">A string containing the grid color.</param>
        public LabelStyleX(int size, string color, int orientation, int step, string gridcolor) : base(size, color)
        {
            this.Size = size;
            this.Color = color;
            this.Orientation = orientation;
            this.Step = step;
            this.GridColor = gridcolor;
        }
        /// <summary>
        /// Creates an instance of the X axis label style object.
        /// </summary>
        /// <param name="size">An integer containing the label size.</param>
        /// <param name="color">A string containing the label color.</param>
        /// <param name="orientation">A integer containing the label orientation.</param>
        /// <param name="step">A integer containing the label step.</param>
        public LabelStyleX(int size, string color, int orientation, int step) : base(size, color)
        {
            this.Size = size;
            this.Color = color;
            this.Orientation = orientation;
            this.Step = step;
            this.GridColor = null;
        }
        /// <summary>
        /// Creates an instance of the X axis label style object.
        /// </summary>
        /// <param name="size">An integer containing the label size.</param>
        /// <param name="color">A string containing the label color.</param>
        /// <param name="orientation">A integer containing the label orientation.</param>
        public LabelStyleX(int size, string color, int orientation) : base(size, color)
        {
            this.Size = size;
            this.Color = color;
            this.Orientation = orientation;
            this.Step = -1;
            this.GridColor = null;
        }
        /// <summary>
        /// Creates an instance of the X axis label style object.
        /// </summary>
        /// <param name="size">An integer containing the label size.</param>
        /// <param name="color">A string containing the label color.</param>
        public LabelStyleX(int size, string color) : base(size, color)
        {
            this.Size = size;
            this.Color = color;
            this.Orientation = 0;
            this.Step = -1;
            this.GridColor = null;
        }
        /// <summary>
        /// Creates an instance of the X axis label style object.
        /// </summary>
        /// <param name="size">An integer containing the label size.</param>
        public LabelStyleX(int size) : base(size)
        {
            this.Size = size;
            this.Color = null;
            this.Orientation = 0;
            this.Step = -1;
            this.GridColor = null;
        }
        #endregion

        #region Public Methods
        /// <summary>
        /// Converts the x axis label style object to a string.
        /// </summary>
        /// <returns>Returns a string representing the x axis label style.</returns>
        public new string ToString()
        {
            StringBuilder sb = new StringBuilder("&x_label_style=");
            sb.Append(base.ToString());
            if (this.Orientation > -1)
                sb.Append(string.Format(",{0}", this.Orientation));
            if (this.Step > 0)
                sb.Append(string.Format(",{0}", this.Step));
            if (this.GridColor.Length > 0)
                sb.Append(string.Format(",{0}", this.GridColor));
            sb.Append("&\r\n");
            return sb.ToString();
        }
        #endregion
    }
}
