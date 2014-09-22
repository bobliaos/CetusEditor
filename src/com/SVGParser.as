package com
{
	import flash.geom.Point;

	public class SVGParser
	{
		private static var svgXML:XML;
		
		private static const PATH_MODE_XML_STRING:String = "<path nodeId='' nodeTypeId='' bindNodeIds='' nodePosition='' textureData='' bindShopId='' shopName='' fill='' deep='' d=''/>";
//		private static const PATH_MODE_XML_STRING:String = "<path nodeId='' nodeTypeId='' bindNodeIds='' nodePosition='' textureData='f,t,30*30,1.1' bindShopId='' fill='' deep='' d=''/>";
//																						textureData = [isTexture:true/flase],[textureType:text/image/both],[textureSize:20*20],[textureRotation:Math.PI]
		private static const DEFAULT_NODE_TYPE_ID:String = "2";
		private static const DEFAULT_FILL:String = "#FFFFFF";
		private static const DEFAULT_TEXTURE_DATA:String = "f,b,20*20,10";
		private static const DEFAULT_DEEP:String = "20";
		private static const DEFAULT_D:String = "";
		
		public function SVGParser()
		{
		}
		
		public static function coverToAllPath(SVGString:String):XML
		{
			svgXML = getClearedXML(SVGString);
			return convertToPathXML(svgXML);
		}
		
		private static function convertToPathXML(origXML:XML):XML
		{
			for (var nodeIndex:String in origXML.children())
			{
				var xml:XML = origXML.children()[nodeIndex];
				if(xml.hasComplexContent())
					convertToPathXML(xml);
				else
					origXML.children()[nodeIndex] = formatSimpleXML(xml);
			}
			return origXML;
		}
		
		private static function formatSimpleXML(xml:XML):XML
		{
			var simpleXML:XML = XML(PATH_MODE_XML_STRING);
			switch(xml.localName())
			{
				case "polyline":
				case "polygon":
					var polygonPointsArr:Array = xml.@points.split(" ");
					var polygonPointsString:String = "M";
					for each(var str:String in polygonPointsArr)
					{
						if(str.indexOf(",") > -1)
						{
							polygonPointsString += (polygonPointsString == "M" ? "" : " L") + str;
						}
					}
					polygonPointsString += "Z";
					xml.@d = polygonPointsString;
					break;
				case "rect":
					var origX:Number = xml.@x;
					var origY:Number = xml.@y;
					var origWidth:Number = xml.@width;
					var origHeight:Number = xml.@height;
					var rectPointsString:String = "M" + origX + "," + origY + " L" + (origX + origWidth) + "," + origY + " L" + (origX + origWidth) + "," + (origY + origHeight) + " L" + origX + "," + (origY + origHeight) + "Z";
					xml.@d = rectPointsString;
					break;
				case "circle":
					var centerX:Number = xml.@cx;
					var centerY:Number = xml.@cy;
					var radius:Number = xml.@r;
					var angleSegments:int = 24;
					var circlePointString:String = "M";
					for(var i:int = 0;i < angleSegments;i ++)
					{
						var angle:Number = i * (Math.PI * 2 / angleSegments);
						var circlePoint:Point = new Point(Math.cos(angle) * radius + centerX,Math.sin(angle) * radius + centerY);
						circlePointString += (circlePointString == 'M' ? '' : ' L') + circlePoint.x.toFixed(2) + "," + circlePoint.y.toFixed(2);
					}
					circlePointString += "Z";
					xml.@d = circlePointString;
					break;
				default:
					break;
			}
			
			var dString:String = xml.@d;
			if(dString.charAt(dString.length - 1).toUpperCase() != 'Z') 
				xml.@d = dString + 'Z';
			
			var bindShopId:String = "";
			if(xml.@bindShopId.toString() == "" && xml.@id.toString() != "")
			{
				bindShopId = xml.@id;
				bindShopId = bindShopId.replace("_","");
				bindShopId = bindShopId.substring(1,bindShopId.length);
			}
			else if(xml.@bindShopId.toString() != "")
			{
				bindShopId = xml.@bindShopId.toString();
//				bindShopId = bindShopId.replace("31_","");
//				bindShopId = bindShopId.replace("32_","");
//				bindShopId = bindShopId.replace("_1_","");
//				bindShopId = bindShopId.replace("_2_","");
			}
			
			simpleXML.@nodeId = xml.@nodeId.toString() != "" ? xml.@nodeId : generateNodeId();
			simpleXML.@nodeTypeId = xml.@nodeTypeId.toString() != "" ? xml.@nodeTypeId : DEFAULT_NODE_TYPE_ID;
			simpleXML.@bindNodeIds = xml.@bindNodeIds.toString() != "" ? xml.@bindNodeIds : "";
			simpleXML.@bindShopId = bindShopId;
			simpleXML.@shopName = xml.@shopName.toString() != "" ? xml.@shopName : "";
			simpleXML.@textureData = xml.@textureData.toString() != "" ? xml.@textureData : DEFAULT_TEXTURE_DATA;
			simpleXML.@fill = xml.@fill.toString() != "" ? xml.@fill : DEFAULT_FILL;
			simpleXML.@deep = xml.@deep.toString() != "" ? xml.@deep : DEFAULT_DEEP;
			simpleXML.@d = xml.@d.toString() != "" ? xml.@d : DEFAULT_D;
			simpleXML.@nodePosition = xml.@nodePosition.toString() != "" ? xml.@nodePosition : calculateNodePosition(simpleXML.@d);
//			simpleXML.@nodePosition = calculateNodePosition(simpleXML.@d);
//			if(simpleXML.@nodeTypeId == "4" || simpleXML.@nodeTypeId == "5") simpleXML.@bindNodeIds = "";
			return simpleXML;
		}
		
		private static function calculateNodePosition(svgPathData:String):String
		{
			const DEGS_TO_RADS:int = Math.PI / 180, UNIT_SIZE:int = 100;
			const DIGIT_0:int = 48, DIGIT_9:int = 57, COMMA:int = 44, SPACE:int = 32, PERIOD:int = 46, MINUS:int = 45;
			
			var idx:int = 1, len:int = svgPathData.length, activeCmd:String,
				x:Number = 0, y:Number = 0, nx:Number = 0, ny:Number = 0, firstX:Number = NaN, firstY:Number = NaN,
				x1:Number = 0, x2:Number = 0, y1:Number = 0, y2:Number = 0,
				rx:Number = 0, ry:Number = 0, xar:Number = 0, laf:Number = 0, sf:Number = 0, cx:Number, cy:Number;
			var points:Array = [];
			
			function eatNum():Number {
				var sidx:int, c:Number, isFloat:Boolean = false, s:String;
				
				while (idx < len) {
					c = svgPathData.charCodeAt(idx);
					if (c !== COMMA && c !== SPACE) break;
					idx++;
				}
				if (c === MINUS)
					sidx = idx++;
				else
					sidx = idx;
				
				while (idx < len) {
					c = svgPathData.charCodeAt(idx);
					if (DIGIT_0 <= c && c <= DIGIT_9)    //0~9
					{
						idx++;
						continue;
					}
					else if (c === PERIOD)               //.
					{
						idx++;
						isFloat = true;
						continue;
					}
					
					s = svgPathData.substring(sidx, idx);
					break;
				}
				return isFloat ? parseFloat(s) : parseInt(s);
			}
			
			function nextIsNum():Boolean {
				var c:int;
				while (idx < len) {
					c = svgPathData.charCodeAt(idx);
					if (c !== COMMA && c !== SPACE) break;
					idx++;
				}
				
				c = svgPathData.charCodeAt(idx);
				return (c === MINUS || (DIGIT_0 <= c && c <= DIGIT_9));
			}
			
			var canRepeat:Boolean;
			activeCmd = svgPathData.charAt(0);
			while (idx <= len) {
				canRepeat = true;
				switch (activeCmd) {
					case 'M':
						x = eatNum();
						y = eatNum();
						points.push(new Point(x, y));
						activeCmd = 'L';
						firstX = x;
						firstY = y;
						break;
					case 'm':
						x += eatNum();
						y += eatNum();
						points.push(new Point(x, y));
						activeCmd = 'L';
						firstX = x;
						firstY = y;
						break;
					case 'Z':
						break;
					case 'z':
						canRepeat = false;
						if (x !== firstX || y !== firstY)
							points.push(new Point(firstX, firstY));
						break;
					case 'L':
					case 'H':
					case 'V':
						nx = (activeCmd === 'V') ? x : eatNum();
						ny = (activeCmd === 'H') ? y : eatNum();
						points.push(new Point(nx, ny));
						x = nx;
						y = ny;
						break;
					case 'l':
					case 'h':
					case 'v':
						nx = (activeCmd === 'v') ? x : (x + eatNum());
						ny = (activeCmd === 'h') ? y : (y + eatNum());
						points.push(new Point(nx, ny));
						x = nx;
						y = ny;
						break;
					case 'C':
						x1 = eatNum();
						y1 = eatNum();
					case 'S':
						if (activeCmd === 'S') {
							x1 = 2 * x - x2;
							y1 = 2 * y - y2;
						}
						x2 = eatNum();
						y2 = eatNum();
						nx = eatNum();
						ny = eatNum();
						points.push(new Point(x1, y1));
						points.push(new Point(x2, y2));
						points.push(new Point(nx, ny));
						x = nx;
						y = ny;
						break;
					case 'c':
						x1 = x + eatNum();
						y1 = y + eatNum();
					case 's':
						if (activeCmd === 's') {
							x1 = 2 * x - x2;
							y1 = 2 * y - y2;
						}
						x2 = x + eatNum();
						y2 = y + eatNum();
						nx = x + eatNum();
						ny = y + eatNum();
						points.push(new Point(x1, y1));
						points.push(new Point(x2, y2));
						points.push(new Point(nx, ny));
						x = nx;
						y = ny;
						break;
					case 'Q':
						x1 = eatNum();
						y1 = eatNum();
					case 'T':
						if (activeCmd === 'T') {
							x1 = 2 * x - x1;
							y1 = 2 * y - y1;
						}
						nx = eatNum();
						ny = eatNum();
						points.push(new Point(x1, y1));
						points.push(new Point(nx, ny));
						x = nx;
						y = ny;
						break;
					case 'q':
						x1 = x + eatNum();
						y1 = y + eatNum();
					case 't':
						if (activeCmd === 't') {
							x1 = 2 * x - x1;
							y1 = 2 * y - y1;
						}
						nx = x + eatNum();
						ny = y + eatNum();
						points.push(new Point(x1, y1));
						points.push(new Point(nx, ny));
						x = nx;
						y = ny;
						break;
					case 'A':
						rx = eatNum();
						ry = eatNum();
						xar = eatNum() * DEGS_TO_RADS;
						laf = eatNum();
						sf = eatNum();
						nx = eatNum();
						ny = eatNum();
						x1 = Math.cos(xar) * (x - nx) / 2 + Math.sin(xar) * (y - ny) / 2;
						y1 = -Math.sin(xar) * (x - nx) / 2 + Math.cos(xar) * (y - ny) / 2;
						
						var norm:Number = Math.sqrt(
							(rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1) /
							(rx * rx * y1 * y1 + ry * ry * x1 * x1));
						if (laf === sf) norm = -norm;
						x2 = norm * rx * y1 / ry;
						y2 = norm * -ry * x1 / rx;
						
						cx = Math.cos(xar) * x2 - Math.sin(xar) * y2 + (x + nx) / 2;
						cy = Math.sin(xar) * x2 - Math.cos(xar) * y2 + (y + ny) / 2;
						
						points.push(new Point(cx, cy));
						x = nx;
						y = ny;
						break;
					default :
						//                    throw  new Error("weird path command:" + activeCmd);
						break;
				}
				
				if (canRepeat && nextIsNum())
					continue;
				activeCmd = svgPathData.charAt(idx++);
			}
			
			var minX:Number = 5000;
			var minY:Number = 5000;
			var maxX:Number = -5000;
			var maxY:Number = -5000;
			for each(var point:Point in points)
			{
				if(point.x < minX) minX = point.x;
				if(point.y < minY) minY = point.y;
				if(point.x > maxX) maxX = point.x;
				if(point.y > maxY) maxY = point.y;
			}
			return ((maxX - minX) * 0.5 + minX).toFixed(2) + "," + ((maxY - minY) * 0.5 + minY).toFixed(2);
		}
		
		public static function generateNodeId():String
		{
			var date:Date = new Date();
			var nodeId:String = "node_" + date.fullYear + ":" + (date.month + 1) + ":" + date.date + ":" + date.toLocaleTimeString().split(" ")[0] + ":" + date.milliseconds + ":" + int(Math.random() * 1000);
			return nodeId;
		}
		
		private static function getClearedXML(SVGString:String):XML
		{
			SVGString = SVGString.replace(/\r/g," ");
			SVGString = SVGString.replace(/\n/g," ");
			SVGString = SVGString.replace(/\t/g," ");
			
			SVGString = SVGString.replace("xml:space=\"preserve\"","");
			SVGString = SVGString.replace("xmlns:aaa=\"http://www.w3.org/XML/1998/namespace\"","");
			SVGString = SVGString.replace("aaa:space=\"preserve\"","");
			SVGString = SVGString.replace(/display=\"none\"/g,"");
			
			var svgXML:XML = XML(SVGString);
			
			if(svgXML.@near.toString() == "") svgXML.@near = 1;
			if(svgXML.@far.toString() == "") svgXML.@far = 28000;
			if(svgXML.@fov.toString() == "") svgXML.@fov = 25;
			if(svgXML.@minDistance.toString() == "") svgXML.@minDistance = 1200;
			if(svgXML.@maxDistance.toString() == "") svgXML.@maxDistance = 2500;
			if(svgXML.@minX.toString() == "") svgXML.@minX = -300;
			if(svgXML.@maxX.toString() == "") svgXML.@maxX = 300;
			if(svgXML.@minY.toString() == "") svgXML.@minY = -150;
			if(svgXML.@maxY.toString() == "") svgXML.@maxY = 250;
			if(svgXML.@minFloorPositionZ.toString() == "") svgXML.@minFloorPositionZ = -12400;
			if(svgXML.@maxFloorPositionZ.toString() == "") svgXML.@maxFloorPositionZ = 11500;
			if(svgXML.@floorGap.toString() == "") svgXML.@floorGap = 800;
			
//			svgXML.normalize();
			return svgXML;
		}
		
		public static function generateNodeXML(localX:Number, localY:Number):XML
		{
			var xmlString:String = "<path nodeTypeId=\"0\" nodePosition=\"" + localX + "," + localY + "\" d=\"M" + localX + "," + localY + "Z\"/>";
			return formatSimpleXML(new XML(xmlString));
		}
	}
}