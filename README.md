# Character Converter

The Character Converter is a Perl script that converts PNG files compatible with the V2 card specification into JSON files and parses them into YAML files. These YAML files can be used with the Oobagooba AI Text Generation WebUI.

```diff
- chara_creator.pl CURRENTLY DOESN'T WORK! NEED TO CREATE NEW TAG (Chara) USING EXIFTOOLS (& PROBABLY XMP) to store encoded (base64) json file contents into an image.
```

## Usage

To use the Character Converter, run the following:

```sh
perl ./chara.pl <filename.png>
```

For a multitude of images (I'd recommend with default `config.json` values so that the only remains being moved to oobagooba are the PNG files and the corresponding YAML files with no unnecessary metadata):

```sh
mkdir ./tmp/
mv ./*.png ./tmp/
for i in ./tmp/*.png; do perl chara.pl $i; done
mv ./tmp/* <oobagooba character folder>
rm -rf ./tmp/
```

## config.json

The `config.json` file is used to specify the parameters for the Character Converter.

```json
{
	"save_json": "false",
	"img_arg": "-all= $filename.png",
	"del_og": "true"
}
```

| Key | Description |
| --- | --- |
| save_json | If true, the JSON file will be saved. |
| img_arg | `exiftool <img_arg>` |
| del_og | If true, the original input image file will be deleted. |

<details>

<summary>img_arg</summary>

The `img_arg` key is used to specify the arguments for the `exiftool` command. The `exiftool` command is used to extract the metadata from the input image file or to change the metadata in the input image file or the new input image.

> `$filename` is the file name of the input image file without the file extension.

Some examples of possible values for the `img_arg` key are:

| Argument | Description |
| --- | --- |
| -all= $filename.png | Remove all metadata from the input image file. |
| -TagsFromFile $filename.png -Chara:all -all:all $filename.yaml | Replace JSON data in `Chara` metadata & replace it with YAML metadata. |
| -TagsFromFile $filename.png "-all:all>all:all" $filename_new.png | Transfer all metadata from the original image to the new image. |

</details>

## new_chara.py

The `new_chara.py` file is used to create a new character card.

<details>

<summary>Dependencies</summary>

**Dependencies**:
- [Oobabooga](https://github.com/oobabooga/text-generation-webui "Common text generation webUI") needs to be running locally using it's API feature on port 5000 (default): http://127.0.0.1:5000/
	- **Model:** *Any*
- [Automatic1111](https://github.com/AUTOMATIC1111/stable-diffusion-webui "Common stable diffusion webUI") needs to be running locally using it's API feature on port 7861 (not default since port 7860 is taken by Oobabooga): http://127.0.0.1:7861/
	- **Model:** *Any*
	- **Embeddings:** bad_prompt_version2-neg FastNegativeV2 realisticvision-negative-embedding
	- **Face Restoration Model:** *Any*

</details>

## License

[LICENSE](./LICENSE)