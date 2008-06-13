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
    /// Represents the background image class
    /// </summary>
    #endregion
    public class BackgroundImage
    {
        #region Private Variables
        string _bg_image_url = null;
        string _bg_image_x = null;
        string _bg_image_y = null;
        #endregion

        #region Public Properties
        /// <summary>
        /// Gets or sets the url of the background image.
        /// </summary>
        public string ImageURL
        {
            set { _bg_image_url = value; }
            get { return _bg_image_url; }
        }
        /// <summary>
        /// Gets or sets a string value containing the horizontal position of the background image.
        /// </summary>
        public string ImageX
        {
            set { _bg_image_x = value; }
            get { return _bg_image_x; }
        }
        /// <summary>
        /// Gets or sets a string value containing the verticle position of the background image.
        /// </summary>
        public string ImageY
        {
            set { _bg_image_y = value; }
            get { return _bg_image_y; }
        }
        #endregion

        #region Constructor
        /// <summary>
        /// Creates an instance of the background image object.
        /// </summary>
        /// <param name="url">A string containing the url of the background image.</param>
        /// <param name="imageX">A string value containing the horizontal position of the background image.</param>
        /// <param name="imageY">A string value containing the verticle position of the background image.</param>
        public BackgroundImage(string url, string imageX, string imageY)
        {
            this._bg_image_url = url;
            this._bg_image_x = imageX;
            this._bg_image_y = imageY;
        }
        /// <summary>
        /// Creates an instance of the background image object.
        /// </summary>
        /// <param name="url">A string containing the url of the background image.</param>
        public BackgroundImage(string url)
        {
            this._bg_image_url = url;
            this._bg_image_x = "center";
            this._bg_image_y = "center";
        }
        #endregion

        #region Public Methods
        /// <summary>
        /// Converts the background image object to a string.
        /// </summary>
        /// <returns>Returns a string representing the BackgroundImage object.</returns>
        public override string ToString()
        {
            StringBuilder sb = new StringBuilder();
            sb.Append(string.Format("&bg_image={0}&\r\n", this._bg_image_url));
            sb.Append(string.Format("&bg_image_x={0}&\r\n", this._bg_image_x));
            sb.Append(string.Format("&bg_image_y={0}&\r\n", this._bg_image_y));
            return sb.ToString();
        }
        #endregion
    }
}
