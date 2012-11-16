/**
 * $Id: Shapes.js,v 1.3 2012-09-12 14:37:44 gaudenz Exp $
 * Copyright (c) 2006-2012, JGraph Ltd
 */

/**
 * Registers shapes.
 */
(function()
{
	// Cube Shape, supports size style
	function CubeShape() { };
	CubeShape.prototype = new mxCylinder();
	CubeShape.prototype.constructor = CubeShape;
	CubeShape.prototype.size = 20;
	CubeShape.prototype.redrawPath = function(path, x, y, w, h, isForeground)
	{
		var s = Math.min(w, Math.min(h, mxUtils.getValue(this.style, 'size', this.size) * this.scale));

		if (isForeground)
		{
			path.moveTo(0, 0);
			path.lineTo(s, s);
			path.end();
		}
		else
		{
			path.moveTo(0, 0);
			path.lineTo(s, s);
			path.close();
			path.end();
		}
	};

	mxCellRenderer.prototype.defaultShapes['w5cube'] = CubeShape;
	mxCellRenderer.prototype.defaultShapes['w5cube1'] = CubeShape;
	mxCellRenderer.prototype.defaultShapes['w5cube2'] = CubeShape;
	mxCellRenderer.prototype.defaultShapes['w5cube3'] = CubeShape;
	mxCellRenderer.prototype.defaultShapes['w5cube4'] = CubeShape;

})();
