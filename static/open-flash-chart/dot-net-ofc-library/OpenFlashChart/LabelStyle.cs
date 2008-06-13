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
    /// Represents the label style object.
    /// </summary>
    #endregion
    public abstract class LabelStyle
    {
        #region Private Variables
        int _size;
        string _color;
        #endregion

        #region Public Properties
        /// <summary>
        /// Gets or sets the label size.
        /// </summary>
        public int Size
        {
            get { return _size; }
            set { _size = value; }
        }
        /// <summary>
        /// Gets or sets the label color.
        /// </summary>
        public string Color
        {
            get { return _color; }
            set { _color = value; }
        }
        #endregion

        #region Constructor
        /// <summary>
        /// Creates an instance of the label style object.
        /// </summary>
        /// <param name="size">An integer containing the label size.</param>
        /// <param name="color">A string containing the label color.</param>
        public LabelStyle(int size, string color)
        {
            this.Size = size;
            this.Color = color;
        }
        /// <summary>
        /// Creates an instance of the label style object.
        /// </summary>
        /// <param name="size">An integer containing the label size.</param>
        public LabelStyle(int size)
        {
            this.Size = size;
            this.Color = null;
        }
        #endregion

        #region Public Methods
        /// <summary>
        /// Converts the axis label style object to a string.
        /// </summary>
        /// <returns>Returns a string representing the axis label style.</returns>
        public override string ToString()
        {
            StringBuilder sb = new StringBuilder(this.Size);
            if (this.Color.Length > 0)
                sb.Append(string.Format(",{0}", this.Color));
            return sb.ToString();
        }
        #endregion
    }
}
