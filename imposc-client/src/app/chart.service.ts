import { Injectable } from '@angular/core';
import { Chart } from './chart';
import { Observable, of } from 'rxjs';
import { MessageService } from './message.service';

@Injectable({ providedIn: 'root' })

export class ChartService {
  CHARTS = 
  [
	{name: "ellipse",description: "Generates a (1, n) orbit sigma response plot \n"},
	{name: "multiplot",description: "Generates multiple plots on a single image\n"},
	{name: "scatter",description: "Generates a scatter plot\n"},
	{name: "timeseries",description: "Generates a time-series plot\n"}
	];

  constructor(private messageService: MessageService) { }
  
  getCharts(): Observable<Chart[]> {
  // TODO: send the message _after_ fetching the charts
  this.messageService.add('ChartService: fetched charts');
  return of(this.CHARTS);}

getChart(name: string): Observable<Chart> {
  // TODO: send the message _after_ fetching the chart
  this.messageService.add(`ChartService: fetched chart name=${name}`);
  return of(this.CHARTS.find(chart => chart.name === name));
}

}
