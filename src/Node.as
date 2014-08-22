package
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class Node extends Sprite
	{
		public var sourceXML:XML;
		public var pathes:Array;
		public var floorId:String;
		public var nodeId:String;
		
		public function Node(pathXML:XML,floorId:String)
		{
			this.sourceXML = pathXML;
			this.floorId = floorId;
			this.nodeId = pathXML.@nodeId;
			
			this.pathes = [];
			
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
			
			//重绘附加的SVG显示对象
		}
	}
}