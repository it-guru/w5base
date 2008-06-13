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
    /// Represents the legend object.
    /// </summary>
    #endregion
    public abstract class Legend
    {
        #region Private Variables
        string _text;
        int _size;
        string _color;
        #endregion

        #region Public Properties
        /// <summary>
        /// Gets or sets a string containing the legend text.
        /// </summary>
        public string Text
        {
            get { return _text; }
            set { _text = value; }
        }
        /// <summary>
        /// Gets or sets an integer of the legend size.
        /// </summary>
        public int Size
        {
            get { return _size; }
            set { _size = value; }
        }
        /// <summary>
        /// Gets or sets a string containing the legend color (Hex Colors)
        /// </summary>
        /// <example>#000000</example>
        public string Color
        {
            get { return _color; }
            set { _color = value; }
        }
        #endregion

        #region Constructor
        /// <summary>
        /// Creates an instance of the Legend object.
        /// </summary>
        /// <param name="text">A string containing the legend text.</param>
        /// <param name="size">An integer of the legend size.</param>
        /// <param name="color">A string containing the legend color (Hex Colors)</param>
        public Legend(string text, int size, string color)
        {
            this.Text = text;
            this.Size = size;
            this.Color = color;
        }
        /// <summary>
        /// Creates an instance of the Legend object.
        /// </summary>
        /// <param name="text">A string containing the legend text.</param>
        public Legend(string text)
        {
            this.Text = text;
            this.Size = -1;
        }
        #endregion

        #region Public Methods
        /// <summary>
        /// Converts the Legend object to a string.
        /// </summary>
        /// <returns>Returns a string of the converted LegendX object.</returns>
        public override string ToString()
        {
            return string.Format("{0},{1},{2}&\r\n", this.Text, this.Size, this.Color);
        }
        #endregion
    }
}
