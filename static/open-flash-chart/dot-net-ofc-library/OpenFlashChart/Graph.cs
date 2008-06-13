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
using System.Collections;
using System.Text;
#endregion

namespace OpenFlashChart
{
    #region Header
    /// <summary>
    /// Represents the graph object.
    /// </summary>
    #endregion
    public class Graph
    {
        #region private variables
        List<Charts.ChartData> _data = new List<OpenFlashChart.Charts.ChartData>();
        ArrayList _x_labels = new ArrayList();
        int _y_min = 0;
        int _y_max = 20;
        int _y2_max = 0;
        int _y2_min = 0;
        int _y_steps = 5;
        int _x_tick_size = -1;
        Title _title = null;

        // Grid Styles
        string _x_axis_color = string.Empty;
        int _x_axis_3d = 0;
        string _x_grid_color = string.Empty;
        int _x_axis_steps = 1;
        string _y_axis_color = string.Empty;
        string _y_grid_color = string.Empty;
        string _y2_axis_color = string.Empty;
        
        // Axis Label Styles
        LabelStyleX _x_label_style = null;
        LabelStyleY _y_label_style = null;
        LabelStyleYRight _y_label_style_right = null;

        // Axis Legend Styles
        Legend _x_legend = null;
        Legend _y_legend = null;
        Legend _y_legend_right = null;

        ArrayList _lines = new ArrayList();
        string _line_default= "&line=3,#87421F&\r\n";

        string _bg_color = string.Empty;
        BackgroundImage _bg_image = null;
        InnerBackground _inner_bg = null;

		// PIE chart ------------
        Charts.Pie _pie = null;

        string _tool_tip = string.Empty;

        ArrayList _y2_lines = new ArrayList();
        #endregion

        #region Public Properties
        /// <summary>
        /// Gets or sets the chart data.
        /// </summary>
        public List<Charts.ChartData> Data
        {
            get { return _data; }
            set { _data = value; }
        }
        /// <summary>
        /// Gets or sets the x-axis label.
        /// </summary>
        public ArrayList LabelsX
        {
            get { return _x_labels; }
            set { _x_labels = value; }
        }
        /// <summary>
        /// Gets or sets the minimum y-axis.
        /// </summary>
        public int MinY
        {
            get { return _y_min; }
            set { _y_min = value; }
        }
        /// <summary>
        /// Gets or sets the maximum y-axis.
        /// </summary>
        public int MaxY
        {
            get { return _y_max; }
            set { _y_max = value; }
        }
        /// <summary>
        /// Gets or sets the steps for they y-axis.
        /// </summary>
        public int StepsY
        {
            get { return _y_steps; }
            set { _y_steps = value; }
        }
        /// <summary>
        /// Gets or sets the tick size on the x-axis.
        /// </summary>
        public int TickSizeX
        {
            get { return _x_tick_size; }
            set { _x_tick_size = value; }
        }
        /// <summary>
        /// Gets or sets the chart title.
        /// </summary>
        public Title Title
        {
            get { return _title; }
            set { _title = value; }
        }
        /// <summary>
        /// Gets or sets the maximum right y-axis.
        /// </summary>
        public int MaxY2
        {
            get { return _y2_max; }
            set { _y2_max = value; }
        }
        /// <summary>
        /// Gets or sets the minimum right y-axis.
        /// </summary>
        public int MinY2
        {
            get { return _y2_min; }
            set { _y2_min = value; }
        }
        /// <summary>
        /// Gets or sets the color of the x-axis.
        /// </summary>
        public string AxisColorX
        {
            get { return _x_axis_color; }
            set { _x_axis_color = value; }
        }
        /// <summary>
        /// Gets or sets the size of a 3D x-axis.
        /// </summary>
        public int AxisX3D
        {
            get { return _x_axis_3d; }
            set { _x_axis_3d = value; }
        }
        /// <summary>
        /// Gets or sets the grid color of the x-axis.
        /// </summary>
        public string GridColorX
        {
            get { return _x_grid_color; }
            set { _x_grid_color = value; }
        }
        /// <summary>
        /// Gets or sets the steps for the x-axis.
        /// </summary>
        public int AxisStepsX
        {
            get { return _x_axis_steps; }
            set { _x_axis_steps = value; }
        }
        /// <summary>
        /// Gets or sets the color of the y-axis.
        /// </summary>
        public string AxisColorY
        {
            get { return _y_axis_color; }
            set { _y_axis_color = value; }
        }
        /// <summary>
        /// Gets or sets the grid color of the y-axis.
        /// </summary>
        public string GridColorY
        {
            get { return _y_grid_color; }
            set { _y_grid_color = value; }
        }
        /// <summary>
        /// Gets or sets the color of the right y-axis.
        /// </summary>
        public string AxisColorYRight
        {
            get { return _y2_axis_color; }
            set { _y2_axis_color = value; }
        }
        /// <summary>
        /// Gets or sets the label style of the x-axis.
        /// </summary>
        public LabelStyleX LabelStyleX
        {
            get { return _x_label_style; }
            set { _x_label_style = value; }
        }
        /// <summary>
        /// Gets or sets the label style of the y-axis.
        /// </summary>
        public LabelStyleY LabelStyleY
        {
            get { return _y_label_style; }
            set { _y_label_style = value; }
        }
        /// <summary>
        /// Gets or sets the label style of the right y-axis.
        /// </summary>
        public LabelStyleYRight LabelStyleYRight
        {
            get { return _y_label_style_right; }
            set { _y_label_style_right = value; }
        }
        /// <summary>
        /// Gets or sets the x-axis legend.
        /// </summary>
        public LegendX LegendX
        {
            get { return (LegendX)_x_legend; }
            set { _x_legend = value; }
        }
        /// <summary>
        /// Gets or sets the y-axis legend.
        /// </summary>
        public LegendY LegendY
        {
            get { return (LegendY)_y_legend; }
            set { _y_legend = value; }
        }
        /// <summary>
        /// Gets or sets the right y-axis legend.
        /// </summary>
        public LegendYRight LegendYRight
        {
            get { return (LegendYRight)_y_legend_right; }
            set { _y_legend_right = value; }
        }
        /// <summary>
        /// Gets or sets the lines.
        /// </summary>
        public ArrayList Lines
        {
            get { return _lines; }
            set { _lines = value; }
        }
        /// <summary>
        /// Gets or sets the default line.
        /// </summary>
        public string LineDefault
        {
            get { return _line_default; }
            set { _line_default = value; }
        }
        /// <summary>
        /// Gets or sets the chart background color.
        /// </summary>
        public string BgColor
        {
            get { return _bg_color; }
            set { _bg_color = value; }
        }
        /// <summary>
        /// Gets or sets the chart background image.
        /// </summary>
        public BackgroundImage BgImage
        {
            get { return _bg_image; }
            set { _bg_image = value; }
        }
        /// <summary>
        /// Gets or sets the chart inner background.
        /// </summary>
        public InnerBackground InnerBg
        {
            get { return _inner_bg; }
            set { _inner_bg = value; }
        }
        /// <summary>
        /// Gets or sets the pie data.
        /// </summary>
        public Charts.Pie Pie
        {
            get { return _pie; }
            set { _pie = value; }
        }
        /// <summary>
        /// Gets or sets the tool tip.
        /// </summary>
        public string ToolTip
        {
            get { return _tool_tip; }
            set { _tool_tip = value; }
        }
        /// <summary>
        /// Gets or sets the right y-axis lines.
        /// </summary>
        public ArrayList LinesY2
        {
            get { return _y2_lines; }
            set { _y2_lines = value; }
        }
        #endregion

        #region Public Methods
        /// <summary>
        /// Converts the graph object to a string of data.
        /// </summary>
        /// <returns>Returns a string of data representing the graph object.</returns>
        public override string ToString()
        {
            StringBuilder sb = new StringBuilder("");
            if (this.Title != null)
                sb.Append(this.Title.ToString());
            if(this.LegendX != null)
                sb.Append(this.LegendX.ToString());
            if(this.LabelStyleX != null)
                sb.Append(this.LabelStyleX.ToString());
            if(this.TickSizeX > 0)
                sb.Append(string.Format("&x_ticks={0}&\r\n", this.TickSizeX));
            if(this.AxisStepsX > 0)
                sb.Append(string.Format("&x_axis_steps={0}&\r\n", this.AxisStepsX));
            if(this.LegendY != null)
                sb.Append(this.LegendY.ToString());
            if (this.LegendYRight != null)
                sb.Append(this.LegendYRight.ToString());
            if (this.LabelStyleY != null)
                sb.Append(this.LabelStyleY.ToString());
            sb.Append(string.Format("&y_ticks=5,10,{0}&\r\n", this.StepsY));
            // Lines/Data/Labels was here moving to object model.
            string suffix = "";
            for (int i = 0; i < this.Data.Count; i++) {
                if(i > 0)
                    suffix = string.Format("_{0}", i + 1);
                Type chart = this.Data[i].GetType();
                if (chart == typeof(Charts.Bar))
                    sb.Append(string.Format("&bar{0}={1}", suffix, this.Data[i].ToString()));
                else if (chart == typeof(Charts.BarFilled))
                    sb.Append(string.Format("&filled_bar{0}={1}", suffix, this.Data[i].ToString()));
                else if (chart == typeof(Charts.AreaHollow))
                    sb.Append(string.Format("&area_hollow{0}={1}", suffix, this.Data[i].ToString()));
                else if (chart == typeof(Charts.LineHollow))
                    sb.Append(string.Format("&line_hollow{0}={1}", suffix, this.Data[i].ToString()));
                else if (chart == typeof(Charts.LineDot))
                    sb.Append(string.Format("&line_dot{0}={1}", suffix, this.Data[i].ToString()));
                else if (chart == typeof(Charts.Line))
                    sb.Append(string.Format("&line{0}={1}", suffix, this.Data[i].ToString()));
                else if (chart == typeof(Charts.Bar3D))
                    sb.Append(string.Format("&bar_3d{0}={1}", suffix, this.Data[i].ToString()));
                else if (chart == typeof(Charts.BarFade))
                    sb.Append(string.Format("&bar_fade{0}={1}", suffix, this.Data[i].ToString()));
                else if (chart == typeof(Charts.BarGlass))
                    sb.Append(string.Format("&bar_glass{0}={1}", suffix, this.Data[i].ToString()));
                sb.Append(string.Format("&values{0}=", suffix));
                for (int j = 0; j < this.Data[i].Data.Count; j++)
                    if (j == 0)
                        sb.Append(this.Data[i].Data[j]);
                    else
                        sb.Append(string.Format(",{0}", this.Data[i].Data[j]));
                sb.Append("&\r\n");
            }
            sb.Append(string.Format("&y_min={0}&\r\n", this.MinY));
            sb.Append(string.Format("&y_max={0}&\r\n", this.MaxY));
            if(this.MaxY2 != 0)
                sb.Append(string.Format("&y2_max={0}&\r\n", this.MaxY2));
            if(this.MinY2 != 0)
                sb.Append(string.Format("&y2_min={0}&\r\n", this.MinY2));
            if(this.BgColor.Length > 0)
                sb.Append(string.Format("&bg_colour={0}&\r\n", this.BgColor));
            if(this.BgImage != null)
                sb.Append(BgImage.ToString());
            if (this.AxisColorX.Length > 0)
            {
                sb.Append(string.Format("&x_axis_colour={0}&\r\n", this.AxisColorX));
                sb.Append(string.Format("&x_grid_colour={0}&\r\n", this.GridColorX));
            }
            if (this.AxisColorY.Length > 0)
                sb.Append(string.Format("&y_axis_colour={0}&\r\n", this.AxisColorY));
            if (this.GridColorY.Length > 0)
                sb.Append(string.Format("&y_grid_colour={0}&\r\n", this.GridColorY));
            if (this.AxisColorYRight.Length > 0)
                sb.Append(string.Format("&y2_axis_colour={0}&\r\n", this.AxisColorYRight));
            if (this.AxisX3D != 0)
                sb.Append(string.Format("&x_axis_3d={0}&\r\n", this.AxisX3D));
            if (this.InnerBg != null)
                sb.Append(this.InnerBg.ToString());
            if (this.Pie != null)
                sb.Append(this.Pie.ToString());
            if (this.ToolTip.Length > 0)
                sb.Append(string.Format("&tool_tip={0}&\r\n", this.ToolTip));
            return sb.ToString();
        }
        #endregion
    }
}
