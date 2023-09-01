# OCCSON

Store, manage and deploy configuration securely with Occson.

## Installation

    curl -o occson -s https://raw.githubusercontent.com/occson/occson.bash/main/occson.bash && chmod u+x occson

## Usage

    occson cp [OPTIONS] <(LocalPath|STDIN)|(OccsonUri|Uri)> <(OccsonUri|Uri)|(LocalPath|STDOUT)>

    Options:
        -a OCCSON_ACCESS_TOKEN,             Occson access token
            --access-token
        -p OCCSON_PASSPHRASE,               Occson passphrase
            --passphrase

    occson run [OPTIONS] <OccsonUri> -- <Command>

    Options:
        -a OCCSON_ACCESS_TOKEN,             Occson access token
            --access-token
        -p OCCSON_PASSPHRASE,               Occson passphrase
            --passphrase


## Example

Download to STDOUT

    occson cp occson://0.1.0/path/to/file.yml -
    occson cp https://api.occson.com/0.1.0/path/to/file.yml -
    occson cp http://host.tld:9292/0.1.0/path/to/file.yml -
    occson cp https://host.tld/0.1.0/path/to/file.yml -

Download to local file

    occson cp occson://0.1.0/path/to/file.yml /local/path/to/file.yml

Upload local file

    occson cp /local/path/to/file.yml occson://0.1.0/path/to/file.yml

Upload content from STDIN

    echo "{ a: 1 }" | occson cp  - occson://0.1.0/path/to/file.yml
    cat /local/path/to/file.yml | occson cp - occson://0.1.0/path/to/file.yml

Run command with downloaded environment variables

    occson run occson://0.1.0/.env -- printenv

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/occson/occson.bash. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The script is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
