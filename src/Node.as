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
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.getQualifiedClassName;
	
	import mx.controls.Image;
	import mx.controls.Label;

	public class Node extends Sprite
	{
		public static var nodeSize:Number = 2;
		
		protected namespace svg = "http://www.w3.org/2000/svg";
		
		public var sourceXML:XML;
		public var pathes:Array;
		public var floorId:String;
		public var nodeId:String;
		public var displaySVGPath:SVGPath;
		
		private var logoSize:Number = 20;
		private var NULL_BITMAP_DATA:BitmapData = new BitmapData(1,1,true,0);
		private var LOGO_BITMAP_DATA:BitmapData = new BitmapData(logoSize,logoSize,true,0);
		public var logo:Bitmap;
		private var ball:Shape;
//		private var label:TextField;
		private var mapping:NodeMapping;
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
			"9":"atm.png",
			"10":""
		};
		
		public function Node(pathXML:XML,floorId:String)
		{
			this.sourceXML = pathXML;
			this.floorId = floorId;
			this.nodeId = pathXML.@nodeId;
			this.alpha = 0.7;
			
			this.pathes = [];
			
			this.logo = new Bitmap(LOGO_BITMAP_DATA,"auto",true);
			this.addChild(this.logo);
			
			mapping = new NodeMapping(sourceXML.@textureData);
			this.addChild(mapping);
			
			this.ball = new Shape();
			this.addChild(this.ball);
			
//			this.label = new TextField();
//			this.addChild(this.label);
//			
//			this.label.background = true;
//			this.label.backgroundColor = 0xFF0033;
//			this.label.defaultTextFormat = new TextFormat("Microsoft Yahei",12,0xFFFFFF);
//			
//			this.label.visible = false;
			
			updateDisplay();
		}
		
		private static const selectedFilterArray:Array = [new DropShadowFilter(0,0,0xFF0000,1,6,6,2)];
		private var _selected:Boolean = false;
		public function set selected(value:Boolean):void
		{
			_selected = value;
			
			this.filters = value ? selectedFilterArray : [];
			
			if(this.displaySVGPath)
				this.displaySVGPath.filters = value ? selectedFilterArray : [];
		}
		public function addPath(path:NodePath):void
		{
			pathes.push(path);
		}
		
		public function get selected():Boolean
		{
			return _selected;
		}
		
		public function updateDisplay():void
		{
			this.x = sourceXML.@nodePosition.split(',')[0];
			this.y = sourceXML.@nodePosition.split(',')[1];
			
			var color:uint = sourceXML.@nodeTypeId == "0" ? 0x0099CC : 0xFF0033;
			color = sourceXML.@nodeTypeId == "3" ? 0xFFFF00 : color;
			color = sourceXML.@nodeTypeId == "2" ? 0xBBBBBB : color;
			
			color = sourceXML.@bindNodeIds == "" ? 0x000000 : color;
			
			var radius:Number = nodeSize;
			this.ball.graphics.clear();
			this.ball.graphics.beginFill(0x222222,0.2);
			this.ball.graphics.drawCircle(0,0,radius + 1);
			this.ball.graphics.beginFill(0xFFFFFF,1);
			this.ball.graphics.drawCircle(0,0,radius + 0.5);
			this.ball.graphics.beginFill(color,1);
			this.ball.graphics.drawCircle(0,0,radius);
			this.ball.graphics.endFill();
			
			var logoURL:String = noteTypeLogos[sourceXML.@nodeTypeId];
			if(logoURL && logoURL != "")
			{
				logo.visible = true;
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void{
					var bitmap:Bitmap = loader.content as Bitmap;
					logo.bitmapData = LOGO_BITMAP_DATA;
					logo.x = - logoSize * 0.7;
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
				logo.visible = false;
				logo.bitmapData = NULL_BITMAP_DATA;
				logo.x = logo.y = 0;
			}
			
			//重绘PATH
			for each(var path:NodePath in pathes)
			{
				path.updateDisplay();
			}
					
			//重绘附加的SVG显示对象
			if(displaySVGPath){
				var doc:SVGDocument = new SVGDocument();
				doc.parse(sourceXML);
				doc.addEventListener(SVGEvent.ELEMENT_ADDED,function(e:SVGEvent):void{
					var container:Sprite = displaySVGPath.parent as Sprite;
					var index:int = container.getChildIndex(displaySVGPath);
					container.removeChild(displaySVGPath);
					
					var element:SVGPath = e.element as SVGPath;
					container.addChildAt(doc,index);
					
					displaySVGPath = element;
				});
				
				if(sourceXML.@nodeTypeId == "1")
				{
					var tmp:DisplayObject = displaySVGPath;
					while(tmp.parent && getQualifiedClassName(tmp.parent) != "com.lorentz.SVG.display::SVG" && tmp.parent != stage)
					{
						tmp = tmp.parent as DisplayObject;
						if(tmp && tmp.parent) tmp.parent.setChildIndex(tmp,0);
					}
				};
			}
			
			//更新贴图
			mapping.setText(sourceXML.@shopName);
			mapping.textureData = sourceXML.@textureData; //"f,b,20*20,10"
			this.rotation = mapping.mappingRotation;
			this.logo.rotation = - mapping.mappingRotation;
//			var arr:Array = textureData.split(",");
//			this.label.visible = arr[0] == "t";
////			mappingTypeDropDownList.selectedItem = arr[1];
//			this.label.width = arr[2].split("*")[0];
//			this.label.height = arr[2].split("*")[1];
//			this.label.text = this.sourceXML.@shopName;
//			this.label.setTextFormat(this.label.defaultTextFormat);
		}
	}
}