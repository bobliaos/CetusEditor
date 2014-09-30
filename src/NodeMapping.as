package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import flashx.textLayout.formats.TextAlign;
	
	public class NodeMapping extends Sprite
	{
		private const MAX_FONT_SIZE:int = 256;
		
		public var isMapping:Boolean = false;
		public var isTextMapping:Boolean = false;
		public var sizePoint:Point = new Point();
		public var imagePercent:Number = 0.6;
		public var mappingRotation:Number = 0;
		
		private var labelWidth:Number = 0;
		private var labelHeight:Number = 0;
		
		private var textureBitmap:Bitmap;
		private var label:TextField;
		
		private var _textureData:String;	//"f,b,20*20,10,12"
		
		public function NodeMapping(textureData:String)
		{
			super();
			
			label = new TextField();
			this.addChild(label);
			label.text = "HELLO WORLD";
			label.border = true;
			label.embedFonts = true;
			label.defaultTextFormat = new TextFormat("bbfont",4);
			this.mouseChildren = this.mouseEnabled = false;
			
			//			textureBitmap = new Bitmap(new BitmapData(20,20));
//			this.addChild(textureBitmap);
			
			textureData = textureData;
		}
		
		public function get textureData():String
		{
			return _textureData;
		}

		public function set textureData(value:String):void
		{
			_textureData = value;
			
			var arr:Array = _textureData.split(",");
			this.isMapping = arr[0] == "t";
			this.isTextMapping = arr[1] == "b" || arr[1] == "t";
			this.isTextMapping = arr[1] == "b" || arr[1] == "i";
			labelWidth = parseInt(arr[2].split("*")[0]);
			labelHeight = parseInt(arr[2].split("*")[1]);
			this.mappingRotation = parseInt(arr[3]);
				
			updateDisplay();
		}
		
		public function setText(text:String):void
		{
			label.text = text;
			labelWidth = label.textWidth + 4;
			labelHeight = label.textHeight + 4;
			
			updateDisplay();
		}
		
		private function updateDisplay():void
		{
//			textureBitmap.x = - this.width * 0.5;
//			textureBitmap.y = - this.height * 0.5;
			
//			textureBitmap.bitmapData.dispose();
//			textureBitmap.bitmapData = new BitmapData(width,height);
//			textureBitmap.bitmapData.fillRect(new Rectangle(0,0,this.width,this.height),Math.random() * 0xFFFFFF);
			
			this.visible = this.isMapping;
			if(this.visible)
			{
				label.width = labelWidth;
				label.height = labelHeight;
				var fontSize:int = 2;
				var tf:TextFormat = new TextFormat(null,fontSize,null,null,null,null,null,null,TextAlign.CENTER);
				label.setTextFormat(tf);
				while((label.textWidth + 4 < labelWidth && label.textHeight + 4 < labelHeight) && fontSize < MAX_FONT_SIZE)
				{
					fontSize ++;
					tf = new TextFormat(null,fontSize);
					label.setTextFormat(tf);
				}
				label.x = - labelWidth * 0.5;
				label.y = - labelHeight * 0.5;
			}
		}
		
	}
}