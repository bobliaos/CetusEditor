package
{
	import com.SVGParser;
	import com.lorentz.SVG.display.SVGDocument;
	import com.lorentz.SVG.display.SVGPath;
	import com.lorentz.SVG.events.SVGEvent;
	import com.lorentz.SVG.parser.SVGParserCommon;
	import com.lorentz.SVG.utils.SVGUtil;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	
	import mx.controls.Image;

	public class Node extends Sprite
	{
		protected namespace svg = "http://www.w3.org/2000/svg";
		
		public var sourceXML:XML;
		public var pathes:Array;
		public var floorId:String;
		public var nodeId:String;
		public var displaySVGPath:SVGPath;
		
		private var logoSize:Number = 40;
		private var NULL_BITMAP_DATA:BitmapData = new BitmapData(1,1,true,0);
		private var LOGO_BITMAP_DATA:BitmapData = new BitmapData(logoSize,logoSize,true,0);
		public var logo:Bitmap;
		private const noteTypeLogos:Object = {
			"0":"",
			"1":"",
			"2":"",
			"3":"machine.png",
			"4":"escalator.png",
			"5":"lift.png",
			"6":"stair.png",
			"7":"toilet.png",
			"8":"service.png",
			"9":"atm.png"
		}
		
		public function Node(pathXML:XML,floorId:String)
		{
			this.sourceXML = pathXML;
			this.floorId = floorId;
			this.nodeId = pathXML.@nodeId;
			
			this.pathes = [];
			
//			var logoContainer:Sprite = new Sprite();
//			this.addChild(logoContainer);
//			logoContainer.mouseChildren = logoContainer.mouseEnabled = false;
			this.logo = new Bitmap(LOGO_BITMAP_DATA,"auto",true);
			this.addChild(this.logo);
			
			updateDisplay();
		}
		
		public function addPath(path:NodePath):void
		{
			pathes.push(path);
		}
		
		public function updateDisplay():void
		{
			this.x = sourceXML.@nodePosition.split(',')[0];
			this.y = sourceXML.@nodePosition.split(',')[1];
			
			var radius:Number = 4;
			this.graphics.clear();
			this.graphics.beginFill(0x222222,0.2);
			this.graphics.drawCircle(0,0,radius + 2);
			this.graphics.beginFill(0xFFFFFF,1);
			this.graphics.drawCircle(0,0,radius + 1);
			var color:uint = sourceXML.@nodeTypeId == "0" ? 0x0099CC : 0xFF0033;
			color = sourceXML.@nodeTypeId == "3" ? 0xFFFF00 : color;
			color = sourceXML.@nodeTypeId == "2" ? 0xBBBBBB : color;
			this.graphics.beginFill(color,1);
			this.graphics.drawCircle(0,0,radius);
			this.graphics.endFill();
			
			var logoURL:String = noteTypeLogos[sourceXML.@nodeTypeId];
			if(logoURL && logoURL != "")
			{
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void{
					var bitmap:Bitmap = loader.content as Bitmap;
					logo.bitmapData = LOGO_BITMAP_DATA;
					logo.x = - logoSize * 0.5;
					logo.y = - logoSize;
					LOGO_BITMAP_DATA.fillRect(LOGO_BITMAP_DATA.rect,0x00000000);
					LOGO_BITMAP_DATA.draw(loader.content,new Matrix(logoSize / bitmap.bitmapData.width,0,0,logoSize / bitmap.bitmapData.height));
					loader.contentLoaderInfo.removeEventListener(Event.COMPLETE,arguments.callee);
					loader = null;
				});
				loader.load(new URLRequest("assets/nodetypelogo/" + logoURL));
			}
			else
			{
				logo.bitmapData = NULL_BITMAP_DATA;
				logo.x = logo.y = 0;
			}
					
			//重绘附加的SVG显示对象
			if(displaySVGPath){
//				displaySVGPath.parent.removeChild(displaySVGPath);
//				displaySVGPath = null;
				
//				var doc:SVGDocument = new SVGDocument();
//				doc.parse(sourceXML);
//				doc.addEventListener(SVGEvent.ELEMENT_ADDED,function(e:SVGEvent):void{
//					var container:Sprite = displaySVGPath.parent as Sprite;					container.removeChild(displaySVGPath);
//					
//					var element:SVGPath = e.element as SVGPath;
//					container.addChild(doc);
//					container.addChild(element);
//					
//					displaySVGPath = element;
//				});
			}
		}
	}
}