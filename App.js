/**
 * Sample React Native TensorIO App
 * https://github.com/phildow/react-native-tensorio-example
 *
 * @format
 * @flow
 * @lint-ignore-every XPLATJSCOPYRIGHT1
 */

import React, {Component} from 'react';
import {Platform, StyleSheet, Text, SafeAreaView, View, Button, Image} from 'react-native';

import ImagePicker from 'react-native-image-picker';
import RNTensorIO from 'react-native-tensorio';

// *** LOAD THE IMAGE MODEL ***

RNTensorIO.load('image-classification');

type Props = {};
export default class App extends Component<Props> {
  constructor(props) {
    super(props);
    
    this._onSelectPhoto = this._onSelectPhoto.bind(this);
    
    this.state = {
      classifications: null,
      image: null
    };
  }

  _onSelectPhoto() {
    ImagePicker.showImagePicker(null, (response) => {
      console.log('Response = ', response);
    
      if (response.didCancel) {
        console.log('User cancelled image picker');
      } else if (response.error) {
        console.log('ImagePicker Error: ', response.error);
      } else if (response.customButton) {
        console.log('User tapped custom button: ', response.customButton);
      } else {
        // const data = 'data:image/jpeg;base64,' + response.data;
        const source = response.uri.replace('file://', '');

        // *** RUN THE IMAGE MODEL ***

        RNTensorIO.run({
          'image': {
            [RNTensorIO.imageKeyData]: source,
            [RNTensorIO.imageKeyFormat]: RNTensorIO.imageTypeFile
          }
        }, (error, results) =>  {
          classifications = results['classification'];
          
          // *** REQUEST THE TOP 5 CLASSIFICATIONS ***

          RNTensorIO.topN(5, 0.1, classifications, (error, top5) => {
            console.log("TOP 5", top5);

            this.setState({
              classifications: top5,
              image: source
            });
          });
        });
      }
    });
  }
  
  render() {
    console.log("STATE", this.state);
    return (
      <SafeAreaView style={styles.container}>
        <Text 
          style={styles.welcome}>
          React Native TensorIO Example
        </Text>
        <Text 
          style={styles.instructions}>
          Select a photo to run an image classification model on it.
        </Text>
        {this.state.image ?  <Image 
          style={styles.image} 
          resizeMode = 'contain'
          source={{
            isStatic: true,
            uri: this.state.image
          }}></Image> : <View style={styles.image}/>}
        <Text
          style={styles.classifications}>
          Classifications: {'\n'}
          {this.state.classifications ? JSON.stringify(this.state.classifications, null, 2) : ''}
        </Text>
        <Button 
          style={styles.button} 
          onPress={this._onSelectPhoto} 
          title="Select Photo">
        </Button>
      </SafeAreaView>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF'
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
    paddingHorizontal: 20
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
    paddingHorizontal: 20
  },
  classifications: {
    padding: 10
  },
  image: {
    flex: 1,
    width: '100%',
    alignSelf:'center',
    backgroundColor: 'black'
  },
  button: {

  }
});
