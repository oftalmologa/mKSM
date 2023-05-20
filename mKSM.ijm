printLabel = true;
saveImage = true;
saveText = false;
saveSingleFile = false;
measureFile = "results.txt"
RANDOM_SEED = 314;

path = getDirectory("image");
imageFileName = getTitle();

run("Line Width...", "line=1");
setForegroundColor(255, 0, 255);

function set_scale(){
	scale_width = 964; //getWidth();
	run("Set Scale...", "distance=" + scale_width + " known=2.960 unit=mm"); 
}

function preprocess() {
	makeRectangle(266, 0, 964, 964);
	run("Crop");
	run("8-bit");
	image = getImageID();
	set_scale();
	run("Auto Threshold", "method=Li white");
	setOption("BlackBackground", true);
	run("Skeletonize");
	run("Dilate");
	run("Dilate");
	run("Dilate");
	run("Dilate");
	run("Dilate");
	run("Dilate");
	run("Dilate");
	run("Dilate");
	run("Erode");
	run("Erode");
	run("Erode");
	run("Erode");
	
}

preprocess();

width = getWidth();
run("Set Measurements...", "center redirect=None decimal=4");
run("Measure");
centerX = getResult('XM', nResults-1) * width / 2.960;
centerY = getResult('YM', nResults-1) * width / 2.960;
selectWindow("Results");
run("Close");

noiseRadius = 30;
sampleSize = 30;
areaSamples = newArray();
sampleX = newArray();
sampleY = newArray();

// ensure determinism
random("seed", RANDOM_SEED);

for (i = 0; i < sampleSize; i++) {
  noiseX = (random() - 0.5) * 2 * noiseRadius;
  noiseY = (random() - 0.5) * 2 * noiseRadius;

  newCenterX = centerX + noiseX;
  newCenterY = centerY + noiseY;
  doWand(newCenterX, newCenterY);

  //run("Enlarge...", "enlarge=2 pixel");
  run("Set Measurements...", "area redirect=None decimal=3");
  run("Measure");
  area = getResult('Area', nResults-1);
  selectWindow("Results");
  run("Close");
  if (area > 0.08) {
    sampleX = Array.concat(sampleX, newCenterX);
    sampleY = Array.concat(sampleY, newCenterY);
    areaSamples = Array.concat(areaSamples, area);
  }
}

if (areaSamples.length > 0) {
  sortedSamples = Array.sort(Array.copy(areaSamples));
  area = sortedSamples[areaSamples.length / 2];

  areaIndex = 0;
  while (areaSamples[areaIndex] != area) {
    areaIndex++;
  }

  doWand(sampleX[areaIndex], sampleY[areaIndex]);
  
  // Compute perimeter and circularity
  run("Set Measurements...", "area perimeter shape redirect=None decimal=3");
  run("Measure");
  area = getResult('Area', nResults-1);
  perimeter = getResult('Perim.', nResults-1);
  circularity = getResult('Circ.', nResults-1);
  selectWindow("Results");
  run("Close");
  close();

  // restore the selection over the original image
  open(path + imageFileName);
  set_scale();
  makeRectangle(266, 0, 964, 964);
  run("Crop");
  run("Restore Selection");

  run("Line Width...", "line=4");
  setForegroundColor(255, 0, 255);
  run("Draw", "slice");
} else {
  area = 0.0;
  perimeter = 0.0;
  circularity = 0.0;
}
 
if (printLabel)
{
  setFont("SansSerif", 14, " antialiased");
  setColor("yellow");
  label = "" + area + " mm2";
  Overlay.drawString(label, centerX, centerY, 0.0);
  Overlay.show();
  run("Select None");
}

if (saveImage) {
  newImageFileName = replace(imageFileName, ".tif", "_faz.tif");
  saveAs("TIFF", path + newImageFileName);
}

if (saveText) {
  textFileName = replace(imageFileName, ".tif", ".txt");
  textFile = File.open(path + textFileName);
  print(textFile, "area: " + area);
  print(textFile, "perimeter: " + perimeter);
  print(textFile, "circularity: " + circularity);
  File.close(textFile);
}

if (saveSingleFile) {
  imageName = replace(imageFileName, ".tif", "");
  fp = path + measureFile;
  File.append(imageName + "," + area + "," + perimeter + "," + circularity, fp);
}
